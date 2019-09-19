# Roger-skyline-1
Проект, автоматизирующий настройку системы Debian для использования ее в качестве веб-сервера, а также настройку самого web-сервера.

## Содержание
- [Настройка VM](#VM)
	- [Предварительная настройка](#prev)
	- [Установка системы](#osinstall)
- [Настройка сети](#network)
- [Создание ключа и проброс его на VM](#key)
- [Настройка системы](#os)
	- [Обновление всех установленных пакетов](#pkgupdate)
	- [Создание sudoer'a](#sudo)
	- [Настройка ssh](#ssh)
	- [Отключение ненужных сервисов](#servicesdisabling)
	- [Настройка crontab](#crontab)
	- [Настройка уведомлений](#mail)
- [Настройка защиты](#protection)
	- [Iptables](#iptables)
	- [Защита от сканирования портов](#noscan)
	- [Защита от DDOS](#noddos)
- [Web-сервер](#web)
	- [Установка и настройка](#setup)
	- [Деплой](#deployment)

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

Теперь появилась возможность заходить по ssh на VM без ввода пароля.

## Настройка системы <a id=os></a>

### Обновление всех установленных пакетов <a id=pkgupdate></a>
```bash
su
apt-get update && apt-get upgrade
```

### Создание sudoer'a <a id=sudo></a>

---

### Настройка ssh на хосте
```bash
ssh-keygen -f rsa_key
ssh-copy-id -i rsa_key.pub remote@192.168.56.2
```

### Настройка ssh на виртуалке
```bash
su
(cat << SSH
PermitRootLogin no
PasswordAuthentication no
Port 2222
SSH
) >> /etc/ssh/sshd_config
service sshd restart
```
Теперь с хоста можно зайти по ssh, используя команду:
`ssh remote@192.168.56.2 -p 2222 -i rsa_key`
