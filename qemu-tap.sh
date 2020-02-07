#!/bin/sh
#
# (c)2015 Christian Kujau <lists@nerdbynature.de>
#
# Based on:
# > How do I bridge a connection from Wi-Fi to TAP on Mac OS X? (for the emulator QEMU)
# > https://superuser.com/a/766251
#
INTERFACE=en1

# set to echo/sudo
DEBUG=sudo

# See how we were called
case $(basename $0) in
	qemu-ifup)
	# Needed for the symlink
	umask 0022
	$DEBUG ln -sf /dev/tap0 /dev/tap
	$DEBUG sysctl -w net.inet.ip.forwarding=1
	$DEBUG sysctl -w net.link.ether.inet.proxyall=1
	$DEBUG sysctl -w net.inet.ip.fw.enable=1
	$DEBUG ifconfig bridge0 create
	$DEBUG ifconfig bridge0 addm $INTERFACE addm tap0
	$DEBUG ifconfig bridge0 up
	$DEBUG natd -interface en1
	$DEBUG ipfw add divert natd ip from any to any via $INTERFACE
	;;

	qemu-ifdown)
	$DEBUG ipfw del 00100
	$DEBUG ipfw del $(sudo ipfw list | grep "ip from any to any via $INTERFACE" | sed -e 's/ .*//g')
	$DEBUG killall -9 natd
	$DEBUG sysctl -w net.inet.ip.forwarding=0
	$DEBUG sysctl -w net.link.ether.inet.proxyall=0
	$DEBUG sysctl -w net.inet.ip.fw.enable=1
	$DEBUG ifconfig bridge0 deletem $INTERFACE deletem tap0
	$DEBUG ifconfig bridge0 down
	$DEBUG ifconfig bridge0 destroy
	;;

	*)
	echo "$0: call me as qemu-ifup or qemu-ifdown!"
	exit 1
	;;
esac
