#!/bin/sh -e
#
# (c)2012 Christian Kujau <lists@nerdbynature.de>
#
# Automatic upgrades for various distributions.
#
# Note: For Linux systems "lsb_release" could be used, but may
# not be installed so we try to determine the distributer the
# old fashion way.
#
if [ ! "$1" = "-f" ]; then
	echo "Usage: `basename $0` [-f]"
	echo
	DEBUG=echo
else
	umask 0022
	PATH=/bin:/usr/bin:/sbin:/usr/sbin:/opt/local/bin:/opt/csw/bin
	date
fi

# Linux
if [ $(uname -s) = "Linux" ]; then
	# Debian/Ubuntu
	if [ -f /etc/debian_version ]; then
		APT_LISTCHANGES_FRONTEND=none
		DEBIAN_FRONTEND=noninteractive
		$DEBUG apt-get -qq update
		$DEBUG apt-get -q -y -V dist-upgrade
		$DEBUG apt-get -q clean
		$DEBUG deborphan --guess-all
	fi

	# Redhat/Fedora/CentOS
	if [ -f /etc/redhat-release ]; then
		# Note: --assumeyes is unknown to older Yum versions
		$DEBUG yum -y update
		$DEBUG yum clean all
	fi
fi

# Darwin/MacOS X
if [ $(uname -s) = "Darwin" ]; then
	# MacOS
	$DEBUG softwareupdate --install --all --verbose

	# MacPorts
	if [ -n "$(port version)" ]; then
		$DEBUG port selfupdate
		$DEBUG port echo outdated 
		$DEBUG port upgrade -u outdated

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
fi

# SunOS/Solaris
if [ $(uname -s) = "SunOS" ]; then
	# IPS?
	:

	# OpenCSW
	if [ -f /opt/csw/etc/pkgutil.conf ]; then
		$DEBUG pkgutil --catalog  --upgrade --yes
	fi

	exit 0
fi
