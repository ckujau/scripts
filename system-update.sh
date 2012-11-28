#!/bin/sh -e
#
# (c)2012 Christian Kujau <lists@nerdbynature.de>
#
# Automatic upgrades for various distributions.
#
if [ "$1" = "--selfupdate" ]; then
	printf "This will update $0 - continue? (y/N)   "
	read c
	if [ "$c" = y ]; then
		wget -q "https://raw.github.com/ckujau/scripts/master/system-update.sh" -O "$0"
		exit $?
	else
		exit $?
	fi
fi

if [ ! "$1" = "-f" -o -z "$2" ]; then
	echo
	echo "Usage: `basename $0` [-f] [logfile]"
	echo "       `basename $0` --selfupdate"
	echo
	if [ "$DEBUG" = 1 ]; then
		DEBUG=echo
		LOG=/dev/null
		set -x
	else
		exit 1
	fi
else
	umask 0022
	PATH=/bin:/usr/bin:/sbin:/usr/sbin:/opt/local/bin:/opt/csw/bin
	 LOG="$2"
	date > "$LOG"
fi
		
rebootmsg() {
if [ "$REBOOT" = 0 ]; then
	# A reboot may be required. But don't flood our motd.
	grep "Reboot may be required" /etc/motd > /dev/null
	if [ $? = 0 ]; then
		:
	else
		echo "$0: Reboot may be required!" | tee -a /etc/motd
	fi
fi
exit 0
}

#
# Find out which OS we are on.
#
# Linux
# Note: For Linux systems "lsb_release" could be used, but may
# not be installed so we try to determine the distributer the
# old fashion way.
if [ $(uname -s) = "Linux" ]; then
	# Debian/Ubuntu
	if [ -f /etc/debian_version ]; then
		(
		APT_LISTCHANGES_FRONTEND=none
		DEBIAN_FRONTEND=noninteractive
		$DEBUG apt-get -qq update
		$DEBUG apt-get -q -y -V dist-upgrade
		$DEBUG apt-get -q clean
		$DEBUG deborphan --guess-all
		) >> "$LOG"

		# Reboot required?
		grep 'linux-image' "$LOG" > /dev/null
		REBOOT=$? rebootmsg
	fi

	# Redhat/Fedora/CentOS
	if [ -f /etc/redhat-release ]; then
		(
		# Note: --assumeyes is unknown to older Yum versions
		$DEBUG yum -y update
		$DEBUG yum clean all
		) >> "$LOG"

		# Reboot required?
		grep 'Verifying  : kernel-' "$LOG" > /dev/null
		REBOOT=$? rebootmsg
	fi
fi

# Darwin/MacOS X
if [ $(uname -s) = "Darwin" ]; then
	# MacOS
	(
	$DEBUG softwareupdate --install --all --verbose
	) >> "$LOG"

	# MacPorts
	if [ -n "$(port version)" ]; then
		(
		$DEBUG port selfupdate
		$DEBUG port echo outdated 
		$DEBUG port upgrade -u outdated
		) >> "$LOG" 2>&1

		# Whan was the last time we did "port clean"?
		LAST="$HOME"/.ports.clean
		if [ -f "$LAST" ]; then
			A=`stat -f %m "$LAST"`
			B=`date +%s`
			# Cleanup every 1209600 seconds (14 days)
			if [ `echo $B - $A | bc` -gt 1209600 ]; then
				echo "port clean -f --all all"
				$DEBUG nice -n 5 port clean -f --all all > /dev/null
				touch "$LAST"
			fi
		else
			touch "$LAST"
		fi
	fi

	# Reboot required?
	grep 'Reboot' "$LOG" > /dev/null
	REBOOT=$? rebootmsg
fi

# SunOS/Solaris
if [ $(uname -s) = "SunOS" ]; then
	# IPS?
	:

	# OpenCSW
	if [ -f /opt/csw/etc/pkgutil.conf ]; then
		(
		$DEBUG pkgutil --catalog  --upgrade --yes
		) >> "$LOG"
	fi

	# Reboot required?
	# grep 'foo' "$LOG" > /dev/null
	# REBOOT=$? rebootmsg
fi
