#!/bin/sh
#
# (c) 2013, Christian Kujau <lists@nerdbynature.de>
#
# Generate checksums of files and store them
# via Extended Attributes
#
# == Requirements ==
#  Darwin: gsha256sum from GNU/coreutils
# FreeBSD: /sbin/sha256
#   Linux: sha256sum from GNU/coreutils
# Solaris: digest, runat from SUNWcsu
#
# === Notes ===
# We could use "shasum", which comes with most Perl installations and
# should be available on most systems. However, being Perl it's slower
# than its C alternatives (openssl, coreutils).
#
# Here is each tool generating the SHA1 checksum of a 1 MB file over 100 runs:
#  shasum COUNT: 100 TIME: 38 seconds		- perl
# openssl COUNT: 100 TIME:  7 seconds		- openssl
# sha1sum COUNT: 100 TIME:  1 seconds		- coreutils
#
# As we're going to have different routines for setting/getting EAs for
# each operating system anyway, we'll have different routines for
# checksums as well.
#
# FIXME:
# - support other message digest algorithms (rmd160, sha3, ...)
# - support other checksum toolsets (coreutils, openssl, rhash)
#
DIGEST="md5"			# md5, sha1, sha256, sha512

# Adjust if needed
PATH=/bin:/usr/bin:/opt/local/bin:/opt/csw/bin:/usr/sfw/bin

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
	# For now let's just assume that GNU coreutils are installed.
	# It's also by far much faster than its perl or openssl alternatives.
	PROGRAM=g${DIGEST}sum
	;;

	Linux)
	# GNU coreutils will be installed on most Linux distributions.
	# It's also by far much faster than its perl or openssl alternatives.
	PROGRAM=${DIGEST}sum
	;;

	SunOS)
	# SUNWcsu should be available. If it's not, we'd have much bigger problems.
	PROGRAM="digest -a $DIGEST"
	;;

	FreeBSD)
	# FreeBSD 10 comes with: md5, sha1, sha256, sha512
	PROGRAM="$DIGEST -q"
	;;

	*)
	do_log "We don't support "$OS", yet :-(" 1
esac

# Main routines, with switches for each OS
case $ACTION in
####### GET
	get)
	case "$OS" in
		Darwin)
		xattr -l -p user.checksum."$DIGEST" -- "$FILE" 2>/dev/null
		;;

		FreeBSD)
		;;

		Linux)
		# NOTE: If the designated EA is not set, getfattr may not return a non-zero
		# exit code. This has been fixed upstream but may not have been picked up
		# by your distribution.
		# http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=520659
		# https://bugzilla.redhat.com/show_bug.cgi?id=660619
		getfattr --absolute-names --name user.checksum."$DIGEST" -- "$FILE" 2>/dev/null | grep "^user.checksum"
		;;

		SunOS)
		runat "$FILE" cat user.checksum."$DIGEST" 2>/dev/null
		;;
	esac

	# Successful?
	[ $? = 0 ] || do_log "ERROR: failed to get user.checksum."$DIGEST" for FILE $FILE!" 1
	;;

####### SET
	set)
	echo "Setting user.checksum."$DIGEST" on "$FILE"..."

	case "$OS" in
		Darwin)
		SUM=$($PROGRAM -- "$FILE" | awk '{print $1}')
		xattr -w user.checksum."$DIGEST" $SUM "$FILE"
		;;

		FreeBSD)
		;;

		Linux)
		SUM=$($PROGRAM -- "$FILE" | awk '{print $1}')
		setfattr --name user.checksum."$DIGEST" --value $SUM -- "$FILE"
		;;

		SunOS)
		SUM=$($PROGRAM -- "$FILE")
		runat "$FILE" "echo $SUM > user.checksum."$DIGEST""
		;;
	esac

	# Successful?
	[ $? = 0 ] || do_log "ERROR: failed to set user.checksum."$DIGEST" for FILE $FILE!" 1
	;;

####### GET-SET)
	get-set)
	case "$OS" in
		Darwin)
		CHECKSUM_S=`xattr -p user.checksum."$DIGEST" -- "$FILE" 2>/dev/null | awk '{print $1}'`
		;;

		FreeBSD)
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
		# Checksum found
		"$0" get "$FILE"
	else
		# No checksum found
		"$0" set "$FILE"
	fi
	;;
	
####### CHECK-SET
	check-set)
	case "$OS" in
		Darwin)
		CHECKSUM_S=`xattr -p user.checksum."$DIGEST" -- "$FILE" 2>/dev/null | awk '{print $1}'`
		;;

		FreeBSD)
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
		# Checksum found
		"$0" check "$FILE"
	else
		# No checksum found
		"$0" set "$FILE"
	fi
	;;

####### CHECK
	check)
	case "$OS" in
		Darwin)
		# Retrieve stored checksum
		CHECKSUM_S=`xattr -p user.checksum."$DIGEST" -- "$FILE" 2>/dev/null | awk '{print $1}'`
		;;

		FreeBSD)
		;;

		Linux)
		CHECKSUM_S=`getfattr --absolute-names --name user.checksum."$DIGEST" --only-values -- "$FILE" 2>/dev/null | awk '{print $1}'`
		;;

		SunOS)
		CHECKSUM_S=`runat "$FILE" cat user.checksum."$DIGEST" 2>/dev/null | awk '{print $1}'`
		;;
	esac

	# Bail out if there is no checksum to compare
	[ -z "$CHECKSUM_S" ] && do_log "ERROR: failed to get user.checksum."$DIGEST" for FILE $FILE!" 1

	# Calculate current checksum
	CHECKSUM_C=`$PROGRAM -- "$FILE" | awk '{print $1}'` || \
		do_log "ERROR: failed to calculate checksum for FILE $FILE!" 1

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
		xattr -d user.checksum."$DIGEST" -- "$FILE"
		;;

		FreeBSD)
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
