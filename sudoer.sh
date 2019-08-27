sudoer () {
    useradd $1 -s /bin/bash -m
    echo -e "$2\n$2" | (passwd $1)
    echo -e "$1\tALL=(ALL:ALL)\tALL" >> /etc/sudoers
}
