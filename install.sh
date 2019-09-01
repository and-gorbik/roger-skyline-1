#!/bin/bash

echo "> network setup"
read
cat interfaces > /etc/network/interfaces
service networking restart
echo "ping to the host"
ping -c 3 192.168.56.1

echo "> packages upgrading"
read
apt-get update >> /var/log/update_script.log
apt-get upgrade -y >> /var/log/update_script.log

echo "> installation of all necessary packages"
read
while read PKG
    do apt-get install -y $PKG >> /var/log/update_script.log
done < requirements

echo "> adding a new sudo user"
read
echo "sudoer name:"
read NAME
echo "password:"
read PASSWD
. sudoer.sh
sudoer $NAME $PASSWD
tail -n 1 /etc/passwd

echo "> ssh setup for user $NAME"
read
cat sshd_config >> /etc/ssh/sshd_config
service sshd restart

echo "> services disabling"
read
while read SERVICE
    do systemctl disable $SERVICE 1>/dev/null 2>/dev/null
done < disabled_services

echo "> crontab setup"
read
cp update.sh /root/update.sh
chmod +x /root/update.sh
echo "0 4 */7 * * /root/update.sh" >> /etc/crontab
echo "@reboot /root/update.sh" >> /etc/crontab

cp notifier.sh /root/notifier.sh
chmod +x /root/notifier.sh
echo "@daily /root/notifier.sh" >> /etc/crontab


# echo "root: $NAME"  >> /etc/aliases
# newaliases

echo "Done!"
