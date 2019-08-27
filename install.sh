#!/bin/bash

echo "> network setup"
cat interfaces >> /etc/network/interfaces
service networking restart

echo "ping to the host"
ping -c 3 192.168.56.1

echo "> packages upgrading"
apt-get update && apt-get upgrade -y

echo "> installation of all necessary packages"
while read PKG
    do apt-get install -y $PKG
done < requirements

echo "> adding a new sudo user"
echo "sudoer name:"
read NAME
echo "password:"
read PASSWD
. sudoer.sh
sudoer $NAME $PASSWD
tail -n 1 /etc/passwd

echo "> ssh setup for user $NAME"
cat sshd_config >> /etc/ssh/sshd_config
service sshd restart

echo "> services disabling"
while read SERVICE
    do systemctl disable $SERVICE
done < disabled_services

echo "> crontab setup"
cp update.sh /root/update.sh
chmod +x /root/update.sh
echo "0 4 */7 * * /root/update.sh" >> /etc/crontab
echo "@reboot /root/update.sh" >> /etc/crontab

cp notifier.sh /root/notifier.sh
chmod +x /root/notifier.sh
echo "@daily /root/notifier.sh" >> /etc/crontab

# echo "root: $NAME"  >> /etc/aliases
# newaliases

    



