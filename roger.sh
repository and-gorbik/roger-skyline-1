#!/bin/bash

apt-get update && apt-get upgrade -y
apt-get install vim sudo mailutils nginx openssl -y

echo -e "sjacelyn\tALL=(ALL:ALL)\tALL" >> /etc/sudoers

cat sshd_config >> /etc/ssh/sshd_config
service sshd restart

while read SERVICE
	do systemctl disable $SERVICE
done < disabled_services

cp update.sh /root/update.sh
chmod +x /root/update.sh
echo "0 4 */7 * * root /root/update.sh" >> /etc/crontab
echo "@reboot root /root/update.sh" >> /etc/crontab

cp notifier.sh /root/notifier.sh
chmod +x /root/notifier.sh
echo "@daily root /root/notifier.sh" >> /etc/crontab

systemctl enable cron

touch /var/mail/sjacelyn
chown sjacelyn /var/mail/sjacelyn

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=RU/ST=IDF/O=School21/OU=roger/CN=192.168.56.2" \
	-keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
cp self-signed.conf /etc/nginx/snippets/self-signed.conf
cp ssl-params.conf /etc/nginx/snippets/ssl-params.conf
cp nginx.conf /etc/nginx/sites-available/default
nginx -t

cp -r www /home/sjacelyn/.
service nginx restart

chmod 740 iptables.sh
sh iptables.sh
iptables-save > /etc/iptables_rules
echo "pre-up iptables-restore < /etc/iptables_rules" >> /etc/network/interfaces
