#!/bin/sh
#
# (C) MMCM
# External proxy for transparent proxying
# https://forum.openwrt.org/viewtopic.php?id=18582
#
SRC=192.168.0.0/24
IFACE=br-lan
ROUTER=192.168.0.2
PROXY=192.168.0.106
PROXY_PORT=3128

case $1 in
	start)
	iptables -t nat -A prerouting_rule  -i $IFACE         ! -s $PROXY           -p tcp --dport 80          -j DNAT --to $PROXY:$PROXY_PORT
	iptables -t nat -A postrouting_rule -o $IFACE           -s $SRC   -d $PROXY                            -j SNAT --to $ROUTER
	iptables        -A forwarding_rule  -i $IFACE -o $IFACE -s $SRC   -d $PROXY -p tcp --dport $PROXY_PORT -j ACCEPT
	;;
	
	stop)
	iptables -t nat -D prerouting_rule  -i $IFACE         ! -s $PROXY           -p tcp --dport 80          -j DNAT --to $PROXY:$PROXY_PORT
	iptables -t nat -D postrouting_rule -o $IFACE           -s $SRC   -d $PROXY                            -j SNAT --to $ROUTER
	iptables        -D forwarding_rule  -i $IFACE -o $IFACE -s $SRC   -d $PROXY -p tcp --dport $PROXY_PORT -j ACCEPT
	;;
	
	*)
	echo "Usage: `basename $0` [start|stop]"
	exit 1
	;;
esac
