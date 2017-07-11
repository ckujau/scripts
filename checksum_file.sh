#!/bin/sh
#
# (c)2013 Christian Kujau <lists@nerdbynature.de>
#
# Generate checksums of files and store them
# via Extended Attributes
#
# == Requirements ==
#  Darwin: /sbin/md5 or openssl
# FreeBSD: /sbin/{md5,sha256} and sysutils/pxattr
#   Linux: md5sum or sha256sum from GNU/coreutils
# Solaris: digest(1) and runat(1) from SUNWcsu
#	   We will also need at least an XPG4 or Korn shell on older Solaris
#	   systems, as older shells may not understand command substitution
#	   with parentheses, as required by POSIX.
#
# Each operating system has its own routines for setting/getting EAs and also
# for calculating checksums. We need to specify the digest algorithm though.
#
# TODO:
# - support other message digest algorithms (rmd160, sha3, ...)
# - support other checksum toolsets (coreutils, openssl, rhash)
#
DIGEST="md5"			# md5, sha1, sha256, sha512

# Adjust if needed
PATH=/bin:/usr/bin:/sbin:/usr/local/bin:/opt/local/bin:/opt/csw/bin:/usr/sfw/bin

print_usage()
{
	echo "Usage: `basename $0` [get]       [file]"
	echo "       `basename $0` [set]       [file]"
	echo "       `basename $0` [get-set]   [file]"
	echo "       `basename $0` [check-set] [file]"
	echo "       `basename $0` [check]     [file]"
	echo "       `basename $0` [remove]    [file]"
	echo ""
	echo "*   get-set - sets a new checksum if none is found, print checksum otherwise."
	echo "* check-set - sets a new checksum if none is found, verify checksum otherwise."
}

if [ $# -ne 2 -o ! -f "$2" ]; then
	print_usage
	exit 1
else
	  ACTION="$1"
	    FILE="$2"
	  OS=$(uname -s)
fi

# Print, exit if necessary
do_log() {
echo "$1"
[ -n "$2" ] && exit $2
}

# Determine the program to generate the digest
case "$OS" in
	Darwin)
	# On a standard MacOS installation, we have the following programs installed:
	#
	# /sbin/md5           - a C binary
	# /usr/bin/shasum     - a Perl wrapper to pick the correct shasum script
	# /usr/bin/shasum5.16 - Calculate the SHA1 hash with Perl 5.16
	# /usr/bin/shasum5.18 - Calculate the SHA1 hash with Perl 5.18
	#
	# The C binary is obviously the fastest and if our DIGEST is set to md5, we
	# will fall back to this one.
	# If we really want to create SHA checksums, we want to use the fastest tool.
	# As a simple benchmark, trying to calculate the SHA-1 checksum of a 5 MB file
	# for 1000 times gave the following results:
	#
	# shasum	- 72 seconds
	# shasum5.16	- 88 seconds
	# shasum5.18	- 68 seconds
	# gsha1sum	- 28 seconds
	# openssl sha1	- 26 seconds *
	#
	# For comparison, when using MD5:
	# md5		- 21 seconds *
	# gmd5sum	- 22 seconds
	# openssl md5	- 25 seconds
	#
	# And so, we will try to choose the fastest program for the job:
	case $DIGEST in
		md5)
		PROGRAM=${DIGEST}
		;;

		sha*)
		openssl dgst -${DIGEST}
		;;
	esac
	;;

	FreeBSD)
	# FreeBSD 10 comes with: md5, sha1, sha256, sha512
	PROGRAM="$DIGEST -q"
	;;

	Linux)
	# GNU/coreutils should be installed on most Linux distributions.
	# It's also by far much faster than its perl or openssl alternatives.
	PROGRAM=${DIGEST}sum
	;;

	SunOS)
	# SUNWcsu should be available. If it's not, we'd have much bigger problems.
	PROGRAM="digest -a $DIGEST"
	;;

	*)
	do_log "We don't support "$OS", yet :-(" 1
	;;
esac

# Main routines, with switches for each OS
case $ACTION in
####### GET
	get)
	printf "user.checksum."$DIGEST": "					# Same formatting for all systems
	case "$OS" in
		Darwin)
		xattr  -p user.checksum."$DIGEST" "$FILE" 2>/dev/null || echo
		;;

		FreeBSD)
		pxattr -n user.checksum."$DIGEST" "$FILE" 2>/dev/null | awk '/user.checksum/ {print $NF}' || echo
		;;

		Linux)
		# NOTE: If the designated EA is not set, getfattr may not return a non-zero
		# exit code. This has been fixed upstream but may not have been picked up
		# by your distribution.
		# http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=520659
		# https://bugzilla.redhat.com/show_bug.cgi?id=660619
		getfattr --only-values --name user.checksum."$DIGEST" -- "$FILE" 2>/dev/null | grep '[[:alnum:]]' || echo
		;;

		SunOS)
		runat "$FILE" cat user.checksum."$DIGEST" 2>/dev/null || echo
		;;
	esac

	# Successful?
	[ $? = 0 ] || do_log "ERROR: failed to get user.checksum."$DIGEST" for file $FILE!" 1
	;;

####### SET
	set)
	echo "Setting user.checksum."$DIGEST" on "$FILE"..."

	case "$OS" in
		Darwin)
		CHECKSUM_C=$($PROGRAM "$FILE" | awk '{print $NF}')
		xattr -w user.checksum."$DIGEST" "$CHECKSUM_C" "$FILE"
		;;

		FreeBSD)
		CHECKSUM_C=$($PROGRAM -- "$FILE")
		pxattr -n user.checksum."$DIGEST" -v "$CHECKSUM_C" "$FILE"
		;;

		Linux)
		CHECKSUM_C=$($PROGRAM -- "$FILE" | awk '{print $1}')
		setfattr --name user.checksum."$DIGEST" --value "$CHECKSUM_C" -- "$FILE"
		;;

		SunOS)
		CHECKSUM_C=$($PROGRAM -- "$FILE")
		runat "$FILE" "echo "$CHECKSUM_C" > user.checksum."$DIGEST""
		;;
	esac

	# Successful?
	[ $? = 0 ] || do_log "ERROR: failed to set user.checksum."$DIGEST" for file $FILE!" 1
	;;

####### GET-SET)
	get-set)
	case "$OS" in
		Darwin)
		CHECKSUM_S=`xattr -p user.checksum."$DIGEST" "$FILE" 2>/dev/null | awk '{print $1}'`
		;;

		FreeBSD)
		CHECKSUM_S=`pxattr -n user.checksum."$DIGEST" "$FILE" 2>/dev/null | awk '/user.checksum/ {print $NF}'`
		;;

		Linux)
		CHECKSUM_S=`getfattr --absolute-names --name user.checksum."$DIGEST" --only-values -- "$FILE" 2>/dev/null | awk '{print $1}'`
		;;

		SunOS)
		CHECKSUM_S=`runat "$FILE" cat user.checksum."$DIGEST" 2>/dev/null`
		;;
	esac
	
	# Did we find a checksum?
	if [ -n "$CHECKSUM_S" ]; then
		# Print out checksum
		echo "user.checksum."$DIGEST": $CHECKSUM_S"
	else
		# Set checksum
		"$0" set "$FILE"
	fi
	;;
	
####### CHECK-SET
	check-set)
	case "$OS" in
		Darwin)
		CHECKSUM_S=`xattr -p user.checksum."$DIGEST" "$FILE" 2>/dev/null | awk '{print $1}'`
		;;

		FreeBSD)
		CHECKSUM_S=`pxattr -n user.checksum."$DIGEST" "$FILE" 2>/dev/null | awk '/user.checksum/ {print $NF}'`
		;;

		Linux)
		CHECKSUM_S=`getfattr --absolute-names --name user.checksum."$DIGEST" --only-values -- "$FILE" 2>/dev/null | awk '{print $1}'`
		;;

		SunOS)
		CHECKSUM_S=`runat "$FILE" cat user.checksum."$DIGEST" 2>/dev/null`
		;;
	esac
	
	# Did we find a checksum?
	if [ -n "$CHECKSUM_S" ]; then
		# Verify checksum
		"$0" check "$FILE"
	else
		# Set checksum
		"$0" set "$FILE"
	fi
	;;

####### CHECK
	check)
	case "$OS" in
		Darwin)
		CHECKSUM_C=$($PROGRAM "$FILE" | awk '{print $NF}')
		CHECKSUM_S=`xattr -p user.checksum."$DIGEST" "$FILE" 2>/dev/null | awk '{print $1}'`
		;;

		FreeBSD)
		CHECKSUM_C=$($PROGRAM -- "$FILE")
		CHECKSUM_S=`pxattr -n user.checksum."$DIGEST" "$FILE" 2>/dev/null | awk '/user.checksum/ {print $NF}'`
		;;

		Linux)
		CHECKSUM_C=$($PROGRAM -- "$FILE" | awk '{print $1}')
		CHECKSUM_S=`getfattr --absolute-names --name user.checksum."$DIGEST" --only-values -- "$FILE" 2>/dev/null | awk '{print $1}'`
		;;

		SunOS)
		CHECKSUM_C=$($PROGRAM -- "$FILE")
		CHECKSUM_S=`runat "$FILE" cat user.checksum."$DIGEST" 2>/dev/null | awk '{print $1}'`
		;;
	esac

	# Bail out if there is no checksum to compare
	[ -z "$CHECKSUM_C" ] || [ -z "$CHECKSUM_S" ] && do_log "ERROR: failed to calculate/get the $DIGEST checksum for file $FILE!" 1

	# Let's compare these two. Set DEBUG=1 to get more verbose output.
	if [ "$CHECKSUM_S" = "$CHECKSUM_C" ]; then
		printf "FILE: $FILE - OK"
		[ "$DEBUG" = 1 ] && echo " ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)" || echo
		true
	else
		printf "FILE: $FILE - FAILED"
		[ "$DEBUG" = 1 ] && echo " ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)" || echo
		false
	fi
	;;

	remove)
	case "$OS" in
		Darwin)
		xattr -d user.checksum."$DIGEST" "$FILE"
		;;

		FreeBSD)
		pxattr -x user.checksum."$DIGEST" "$FILE"
		;;

		Linux)
		setfattr --remove user.checksum."$DIGEST" -- "$FILE"
		;;

		SunOS)
		runat "$FILE" rm user.checksum."$DIGEST"
		;;
	esac
	;;

	*)
	print_usage
	exit 1
	;;
esac
