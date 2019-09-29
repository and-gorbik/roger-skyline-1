# Roger-skyline-1
Проект, автоматизирующий настройку системы Debian для использования ее в качестве веб-сервера, а также настройку самого web-сервера.

## Содержание
- [Настройка VM](#VM)
	- [Предварительная настройка](#prev)
	- [Установка системы](#osinstall)
- [Настройка сети](#network)
- [Создание ключа и проброс его на VM](#key)
- [Настройка системы](#os)
	- [Обновление и установка пакетов](#pkgupdate)
	- [Создание sudoer'a](#sudo)
	- [Настройка ssh](#ssh)
	- [Отключение ненужных сервисов](#servicesdisabling)
	- [Настройка crontab](#crontab)
	- [Настройка почты](#mail)
- [Настройка Web-сервера](#web)
	- [Создание ssl-сертификата и ключа](#ssl)
	- [Настройка nginx с подддержкой SSL сертификатов](#nginx)
- [Настройка защиты](#protection)
	- [Iptables](#iptables)
	- [Защита от сканирования портов](#noscan)
	- [Защита от DDOS](#noddos)
- [Полезные ссылки](#srcs)

## Настройка VM <a id=VM></a>

###  Предварительная настройка <a id=prev></a>
- Размер диска: 8Гб (по умолчанию), фиксированный размер
- Размер оперативки: 1Гб (по умолчанию)
- Два сетевых адаптера:
	- `NAT` - для использования интернета
	- `Host-only Adapter` - для связи с хост-машиной: 192.168.56.1/30, отключить DHCP-сервер
		>Это делается в основном окне VirtualBox, в разделе Global Tools -> параметры сети vboxnet0

### Установка системы <a id=osinstall></a>
- Образ: `debian-10.1.0-amd64-netinst`
- Non-root пользователь:
	- логин: sjacelyn
	- пароль: 12345
- Ручная настройка разделов диска:
	- `/` - 4.2Gb, Primary (в начале диска), Ext4
	- `swap` - 1Gb, Logical (в начале диска), swap area
	- `/home` - остальное место, Logical, Ext4
- Зеркало пакетного менеджера: `ftp.ru.debian.org`
- Установленные по умолчанию пакеты:
	- ssh-server
	- стандартные системные утилиты
- Установить  GRUB: да


```
Все действия выполнять от root'a и из директории с проектом
```

## Настройка сети <a id=network></a>
- Отредактировать файл **/etc/network/interfaces**:
```bash
cp interfaces /etc/network/interfaces
```
- Перезапустить сервис **networking**:
```bash
service networking restart
```
- Проверить соединения с хост-машиной:
```bash
ping -c 3 192.168.56.1
```

## Создание ключа и проброс его на VM <a id=key></a>
- Сгенерировать ключ (на хосте):
```bash
ssh-keygen -f roger-key
```
- Скопировать ключ на VM для пользователя `sjacelyn`:
```bash
ssh-copy-id -i roger-key.pub sjacelyn@192.168.56.2
```
- Ввести пароль (12345)


## Настройка системы <a id=os></a>

### Обновление и установка пакетов <a id=pkgupdate></a>
```bash
su
apt-get update && apt-get upgrade -y
apt-get install vim sudo mailutils -y
```

### Создание sudoer'a <a id=sudo></a>
```bash
echo -e "sjacelyn\tALL=(ALL:ALL)\tALL" >> /etc/sudoers
```

### Настройка ssh <a id=ssh></a>
- Изменить файл `/etc/ssh/sshd_config`: 
```bash
cat sshd_config >> /etc/ssh/sshd_config
```
- Перезапустить сервис `sshd`:
```bash
service sshd restart
```
Теперь с хоста можно зайти по ssh, используя команду:
`ssh sjacelyn@192.168.56.2 -p 2222 -i roger-key`

### Отключение ненужных сервисов <a id=servicesdisabling></a>
```bash
while read SERVICE
	do systemctl disable $SERVICE
done < disabled_services
```

### Настройка crontab <a id=crontab></a>
```bash
cp update.sh /root/update.sh
chmod +x /root/update.sh
echo "0 4 */7 * * /root/update.sh" >> /etc/crontab
echo "@reboot /root/update.sh" >> /etc/crontab

cp notifier.sh /root/notifier.sh
chmod +x /root/notifier.sh
echo "@daily /root/notifier.sh" >> /etc/crontab
```

### Настройка почты <a id=mail></a>
```bash
touch /var/mail/sjacelyn
chown sjacelyn /var/mail/sjacelyn
```

## Настройка Web-сервера <a id=web></a>

### Создание SSL сертификата и ключа <a id=ssl></a>

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/nginx-selfsigned.key \
-out /etc/ssl/certs/nginx-selfsigned.crt
```
Эта команда создает самоподписанный сертификат (`/etc/ssl/certs/nginx-selfsigned.crt`) вместе с rsa-ключом длины 2048 бит (`/etc/ssl/private/nginx-selfsigned.key`), действительные в течение 365 дней.
Далее требуется заполнить информацию в сертификате:

| Поле | Значение |
| --- | --- |
| Country Name | RU |
| State |  |
| City | Moscow |
| Company | School21 |
| Section |  |
| Common Name | 192.168.56.2 |

Нужны также специальные ключи Диффи-Хеллмана для поддержки PFS*:
```bash
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
```
> \*Совершенная прямая секретность (англ. Perfect forward secrecy, PFS) — свойство некоторых протоколов согласования ключа, которое гарантирует, что сессионные ключи, полученные при помощи набора ключей долговременного пользования, не будут скомпрометированы при компрометации одного из долговременных ключей. (wikipedia)

### Настройка nginx с подддержкой SSL сертификатов <a id=nginx></a>
Создать сниппет, показывающий папку, где лежат сертификат и ключ:
```bash
cp self-signed.conf /etc/nginx/snippets/self-signed.conf
```
Создать сниппет с настройками сертификата:
```bash
cp ssl-params.conf /etc/nginx/snippets/ssl-params.conf 
```
Создать конфигурацию серверу и проверить правильность конфига:
```bash
cp nginx.conf /etc/nginx/sites-available/default
nginx -t
```
Создать отдаваемую сервером страницу:
```bash
cp login.html /home/sjacelyn/www/login.html
```
Перезапустить nginx:
```bash
service nginx restart
```

Теперь сервер может отдавать статические html-странички из директории `/home/sjacelyn/www` по протоколу https.
Однако, т.к. сертификат самоподписанный, браузер выдаст предупреждение.

Проверить работу сервера можно, набрав в браузере: `https://192.168.56.2/login.html`

## Настройка защиты <a id=protection></a>

## Полезные ссылки <a id=srcs></a>
- [Типы сетей в virtualbox](https://techlist.top/virtualbox-network-settings-part-1/)
- [Настройка iptables](https://serveradmin.ru/nastroyka-iptables-v-centos-7/)
- [Настройка nginx с самоподписанным сертификатом](https://abc-server.com/ru/blog/administration/creating-ssl-for-nginx-in-ubuntu-1604/)
- [Красивая страничка логина](https://codepen.io/colorlib/pen/rxddKy)
