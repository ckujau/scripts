#!/bin/sh
#
# (c)2014 Christian Kujau <lists@nerdbynature.de>
# MacPorts cleanup
#
PATH=/bin:/usr/bin:/opt/local/bin
LAST="$HOME"/.ports.clean
umask 0022

case $1 in
	a)
	port echo active | awk '{print $1 $2}'
	;;

	i)
	port echo inactive | awk '{print $1 $2}'
	;;

	u)
	port selfupdate
	port echo outdated 
	port upgrade -u outdated
	if [ -f "$LAST" ]; then
		A=`stat -f %m "$LAST"`
		B=`date +%s`
		# Cleanup every 1209600 seconds (14 days)
		if [ `echo $B - $A | bc` -gt 1209600 ]; then
			echo "port clean all..."
			echo nice -n20 port clean -f --all all > /dev/null
		fi
	else
		touch "$LAST"
	fi
	;;

	*)
	echo "Usage: `basename $0` [i|a|u]"
	echo "i - list inactive"
	echo "a - list active"
	echo "u - upgrade"
	exit 1
	;;
esac
