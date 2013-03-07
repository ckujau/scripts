#!/bin/sh
#
# (c)2012 Christian Kujau <lists@nerdbynature.de>
#
# Automatic upgrades for various distributions.
#
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/opt/local/bin:/opt/csw/bin
 URL=https://raw.github.com/ckujau/scripts/master/system-update.sh
 LOG=/var/log/system-update.log

umask 0022

case $1 in
	start)
	:
	;;

	selfupdate)
	printf "This will update $0 - continue? (y/N)   "
	read c
	if [ "$c" = y ]; then
		FILE=`mktemp`
		wget -q "$URL" -O "$FILE"
		grep '^# END' "$FILE" > /dev/null

		if [ $? = 0 ]; then
			mv "$FILE" "$0" || exit $?
			exit 0
		else
			echo "Something went wrong, update failed!"
			rm "$FILE" || exit $?
			exit 2
		fi
	else
		exit $?
	fi
	;;

	*)
	echo "Usage: `basename $0` [start|selfupdate]"
	exit 1
	;;
esac
		
rebootmsg() {
# A reboot may be required. But don't flood our motd.
grep "Reboot may be required" /etc/motd > /dev/null
if [ $? = 0 ]; then
	:
else
	echo "$0: Reboot may be required! (`date`)" | tee -a /etc/motd
fi
exit 0
}

die() {
echo "$0 failed: $1"
[ -z "$2" ] && exit "$2"
}

# Redirect everything LOG
exec >> "$LOG" 2>&1

#
# Find out which OS we are on.
#
# Linux
# Note: For Linux systems "lsb_release" could be used, but may
# not be installed so we try to determine the distribution the
# old fashioned way.
if [ $(uname -s) = "Linux" ]; then
	# Debian/Ubuntu
	if [ -f /etc/debian_version ]; then
		APT_LISTCHANGES_FRONTEND=none
		DEBIAN_FRONTEND=noninteractive
		$DEBUG apt-get --quiet=2 update || die "apt-get update" 1
		$DEBUG apt-get --quiet --yes --verbose-versions \
			--option Dpkg::Options::="--force-confdef --force-confold" dist-upgrade \
						|| die "apt-get dist-upgrade" 1
		$DEBUG apt-get --quiet clean	|| die "apt-get clean" 1
		$DEBUG deborphan --guess-all	|| die "deborphan --guess-all" 1

		# Reboot required?
		grep -q 'linux-image' "$LOG" && rebootmsg
	fi

	# Gentoo
	if [ -f /etc/gentoo-release ]; then
		NOCOLOR=true
		emerge --sync > /dev/null || die "emerge --sync"  1
		emerge portage            || die "emerge portage" 1
		emerge --update --deep --newuse --with-bdeps=y world || die "emerge update" 1
		emerge --depclean	|| die "emerge --depclean" 1
		revdep-rebuild		|| die "revdep-rebuild" 1
		eselect news read new	|| die "eselect news read new" 1

#		# Reboot required?
#		grep -q 'Verifying  : kernel-' "$LOG" && rebootmsg
	fi

	# Redhat/Fedora/CentOS
	if [ -f /etc/redhat-release ]; then
		# Note: --assumeyes is unknown to older Yum versions
		$DEBUG yum -y update	  || die "yum update" 1
		$DEBUG yum clean packages || die "yum clean packages" 1

		# Reboot required?
		grep -A10000 Installing "$LOG" | grep -q kernel- && rebootmsg
	fi

	# SUSE, openSUSE
	if [ -f /etc/SuSE-release ]; then
		$DEBUG zypper --quiet --non-interactive update	|| die "zypper update" 1
		$DEBUG zypper clean				|| die "zypper clean" 1

#		# Reboot required?
#		grep -q 'Verifying  : kernel-' "$LOG" && rebootmsg
	fi
fi

# Darwin/MacOS X
if [ $(uname -s) = "Darwin" ]; then
	# MacOS
	$DEBUG softwareupdate --install --all --verbose
	$DEBUG diskutil umount "Recovery HD"

	# MacPorts
	if [ -n "$(port version)" ]; then
		$DEBUG port selfupdate		|| die "port selfupdate" 1
		$DEBUG port echo outdated	|| die "port echo outdated" 1
		$DEBUG port upgrade -u outdated	|| die "port upgrade -u outdated" 1

		# Whan was the last time we did "port clean"?
		LAST="$HOME"/.ports.clean
		if [ -f "$LAST" ]; then
			A=`stat -f %m "$LAST"`
			B=`date +%s`
			# Cleanup every 1209600 seconds (14 days)
			if [ `echo $B - $A | bc` -gt 1209600 ]; then
				echo "port clean -f --all all"
				$DEBUG nice -n 5 port clean -f --all all > /dev/null \
						|| die "port clean" 1
				touch "$LAST"
			fi
		else
			touch "$LAST"
		fi
	fi

	# Reboot required?
	grep -q 'Reboot' "$LOG" && rebootmsg
fi

# SunOS/Solaris
if [ $(uname -s) = "SunOS" ]; then
	# IPS?
	:

	# OpenCSW
	if [ -f /opt/csw/etc/pkgutil.conf ]; then
		$DEBUG pkgutil --catalog  --upgrade --yes || die "pkgutil --upgrade" 1
	fi

	# Reboot required?
	# grep 'foo' "$LOG" > /dev/null && rebootmsg
fi

# END
