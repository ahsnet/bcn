#!/bin/bash
# Configure SSH Daemon to Permit access root remotely via OpenSSH server
# Author: Bonveio <github.com/Bonveio/BonvScripts>

# Check if machine has a sudo package
if [[ ! "$(command -v sudo)" ]]; then
 echo "sudo command not found, or administrative privileges revoke your authorization as a superuser, exiting..."
 exit 1
fi

# Tricking the script to run only at non-configured sshd config
# All of my distributed sshd configs are root allowed and password auth allowed, so checking if 'BonvScripts' word is found in the script is more variant.
if [[ "$(cat < /etc/ssh/sshd_config | grep -c "BonvScripts")" -eq 1 ]]; then
 echo "BonvScripts already configured your OpenSSH server, exiting.."
 exit 1
 else
 echo "## configured by BonvScripts auto-root script" >> /etc/ssh/sshd_config
fi

until [[ "$newsshpass" =~ ^[a-zA-Z0-9_]+$ ]]; do
	read -rp " Enter your new Root Password: " -e newsshpass
done

# Checking ssh daemon if PermitRootLogin is not allowed yet
if [[ "$(sshd -T | grep -i "permitrootlogin" | awk '{print $2}')" != "yes" ]]; then
 echo "Allowing PermitRootLogin..."
 sed -i 's/[PermitRootLogin].*//g' /etc/ssh/sshd_config
 echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
 else
 echo "PermitRootLogin already allowed.."
fi

# Checking if PasswordAuthentication is not allowed yet
if [[ "$(sshd -T | grep -i "passwordauthentication" | awk '{print $2}')" != "yes" ]]; then
 echo "Allowing PasswordAuthentication..."
 sed -i 's/[PasswordAuthentication].*//g' /etc/ssh/sshd_config
 echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
 else
 echo "PasswordAuthentication already allowed"
fi

# Changing root Password
echo -e "$newsshpass\n$newsshpass\n" | sudo passwd root &> /dev/null

# Restarting OpenSSH Service to save all of our changes
echo "Restarting openssh service..."
if [[ ! "$(command -v systemctl)" ]]; then
 service ssh restart &> /dev/null
 service sshd restart &> /dev/null
 else
 systemctl restart ssh &> /dev/null
 systemctl restart sshd &> /dev/null
fi

echo -e "\nNow check if your SSH are accessible using root\nIP Address: $(wget -4qO- http://ipinfo.io/ip || curl -4sSL http://ipinfo.io/ip)\nSSH Port: $(ss -4tlnp | grep -i "ssh" | awk '{print $4}' | cut -d: -f2 | head -n1)\n"

exit 0
