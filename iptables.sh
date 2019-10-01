#!/bin/bash

export HOST_IP=192.168.56.1
export DEV=enp0s8
export SSH_PORT=2222

# flush all
iptables -F
iptables -F -t nat
iptables -F -t mangle
iptables -X
iptables -t nat -X
iptables -t mangle -X

# set default rules
iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT

# allow lo
iptables -A INPUT -i lo -j ACCEPT

# allow response packages
iptables -A INPUT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p udp -m conntrack --ctstate ESTABLISHED -j ACCEPT

# allow ssh
iptables -A INPUT -p tcp -i $DEV -s $HOST_IP --dport $SSH_PORT -j ACCEPT

# allow http, https for web-server
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
