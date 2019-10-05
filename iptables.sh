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

# deny portscan
iptables -A INPUT -m recent --rcheck --seconds 120 --name FUCKOFF -j DROP
iptables -A INPUT -p tcp -m multiport ! --dports $SSH_PORT,80,443 -m recent --set --name FUCKOFF -j DROP

# enable dos protection
iptables -N brute_check
iptables -A brute_check -m recent --update --seconds 60 --hitcount 3 -j DROP
iptables -A brute_check -m recent --set -j ACCEPT
iptables -A INPUT -m conntrack --ctstate NEW -p tcp -m multiport ! --dports $SSH_PORT,80,443 -j brute_check

# set default rules
iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT

# deny invalid packages
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP  

# deny null packages
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# deny bad tcp packages
iptables -A INPUT -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
iptables -A OUTPUT -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

# allow lo
iptables -A INPUT -i lo -j ACCEPT

# allow response packages
iptables -A INPUT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p udp -m conntrack --ctstate ESTABLISHED -j ACCEPT

# allow ssh
iptables -A INPUT -p tcp -i $DEV -s $HOST_IP --dport $SSH_PORT -j ACCEPT

# allow safe icmp messages
# iptables -A INPUT -p icmp -icmp-type 3,8,12 -j ACCEPT

# allow http, https for web-server
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
