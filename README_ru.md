# roger-skyline-1
Проект, автоматизирующий настройку системы Debian для использования ее в качестве веб-сервера, а также настройку самого web-сервера.

## Настройка VM

###  Предварительная настройка
- Размер диска: 8Гб (по умолчанию), фиксированный размер
- Размер оперативки: 1Гб (по умолчанию)
- Два сетевых адаптера:
	- `NAT` - для использования интернета
	- `Host-only Adapter` - для связи с хост-машиной: 192.168.56.1/30, отключить DHCP-сервер
		>Это делается в основном окне VirtualBox, в разделе Global Tools -> параметры сети vboxnet0

### Установка системы
- Образ: [Debian 9.9.0-amd64-netinst.iso](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.9.0-amd64-netinst.iso)
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

### Обновление всех установленных пакетов
```bash
su
apt-get update && apt-get upgrade
```

### Настройка сети на виртуалке
```bash
su
(cat << NETWORK
# virtual host adapter"
auto enp0s8
iface enp0s8 inet static
address 192.168.56.2
netmask 255.255.255.252
NETWORK
) >> /etc/network/interfaces
service networking restart
# проверка
ping -c 3 192.168.56.1
```

### Создание нового пользователя и добавление его в sudoers
```bash
su
# username: remote
# password: 12345
useradd remote -s /bin/bash -m
echo -e "12345\n12345" | (passwd remote)
apt-get install sudo -y
# добавление пользователя в sudoers
echo -e "remote\tALL=(ALL:ALL)\tALL" >> /etc/sudoers
# проверка
su - remote
sudo apt-get install vim -y
```

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
