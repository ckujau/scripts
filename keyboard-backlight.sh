#!/bin/sh
#
# Originally written by Francisco Diéguez Souto (frandieguez@ubuntu.com)
# This script is licensed under MIT License.
#
# This program just modifies the value of backlight keyboard for Apple Laptops
# You must run it as root user or via sudo.
# As a shortcut you could allow to admin users to run via sudo without password
# prompt. To do this you must add sudoers file the next contents:
#
#  Cmnd_Alias CMDS = /usr/local/bin/keyboard-backlight.sh
#  %admin ALL = (ALL) NOPASSWD: CMDS
#
# After this you can use this script as follows:
#
#     Increase backlight keyboard:
#	    $ sudo keyboard-backlight.sh up
#     Decrease backlight keyboard:
#	    $ sudo keyboard-backlight.sh down
#     Increase to total value backlight keyboard:
#	    $ sudo keyboard-backlight.sh total
#     Turn off backlight keyboard:
#	    $ sudo keyboard-backlight.sh off
#
# You can customize the amount of backlight by step by changing the INCREMENT
# variable as you want it.
#

 BACKLIGHT="/sys/class/leds/smc::kbd_backlight/brightness"
BRIGHTNESS=$(cat $BACKLIGHT)
 INCREMENT=20

if [ $(id -ru) -ne 0 ]; then
	echo "Please run this program as superuser!"
	exit 1
fi

die() {
echo "Brightness is already $1"
exit 1
}

case $1 in
	up)
	# BRIGHTNESS will be capped at 255 anyway
	if [ $BRIGHTNESS -lt 255 ]; then
		expr $BRIGHTNESS + $INCREMENT > $BACKLIGHT
	else
		die $BRIGHTNESS
	fi
	;;

	down)
	if [ $BRIGHTNESS -gt 0 ]; then
		VALUE=`expr $BRIGHTNESS - $INCREMENT`

		# BRIGHTNESS cannot be negative
		[ $VALUE -lt 0 ] && VALUE=0
		echo $VALUE > $BACKLIGHT
	else
		die $BRIGHTNESS
	fi
	;;

	total)
	echo 255 > $BACKLIGHT
	;;

	off)
	echo 0 > $BACKLIGHT
	;;

	[\-0-9]*)
	VALUE=$1
	if [ $VALUE -ge 0 ] && [ $VALUE -le 255 ]; then
		echo $VALUE > $BACKLIGHT
	else
		echo "Invalid argument ($VALUE). Please provide a value from 0 to 255!"
		exit 1
	fi
	;;

	*)
		echo "Use: `basename $0` [up|down|total|off|value]"
		exit 1
	;;
esac

echo "Brightness set to $(cat $BACKLIGHT)"
