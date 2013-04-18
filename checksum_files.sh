#!/bin/sh
#
# (c) 2013, Christian Kujau <lists@nerdbynature.de>
#
# Generate checksums of files and store them via
# Extended Attributes
#
# Set DEBUG=1 to get more verbose output
#
# === Notes ===
# We could use "shasum", which lets us choose the (SHA based) digest. However,
# "shasum" is a Perl script and preliminary tests have shown that it's
# twice as slow as "sha1sum" (a C binary) from the coreutils package.
#
# We have some actual numbers now: generating the SHA1 checksum
# of a 1 MB file, for 100 runs:
#  shasum COUNT: 100 TIME: 38 seconds		- perl
# openssl COUNT: 100 TIME:  7 seconds		- openssl
# sha1sum COUNT: 100 TIME:  1 seconds		- coreutils
#
# As we're going to have different routines for setting/getting EAs for each
# operating system anyway, we'll have different routines for checksums as well.
#
DIGEST="sha256"			# sha1, sha224, sha256, sha384, sha512

# Adjust if needed
PATH=/bin:/usr/bin:/opt/local/bin:/opt/csw/bin:/usr/sfw/bin

# We'll need the length of our DIGEST later on. Instead of (laboriously)
# trying to find this out ourselves, let's just hardcore those values.
case $DIGEST in
	  sha1) LENGTH=40 ;;
	sha224) LENGTH=56 ;; 
	sha256) LENGTH=64 ;; 
	sha384) LENGTH=96 ;; 
	sha512)	LENGTH=128 ;;
	*)
	echo "ERROR: Unknown DIGEST ($DIGEST) in $0, cannot continue!"
	exit 2
	;;
esac

print_usage()
{
	echo "Usage: `basename $0` [get]       [file]"
	echo "       `basename $0` [set]       [file]"
	echo "       `basename $0` [check-set] [file]"
	echo "       `basename $0` [check]     [file]"
}

if [ $# -ne 2 -o ! -f "$2" ]; then
	print_usage
	exit 1
else
	ACTION="$1"
	  FILE="$2"
fi

# Print, exit if necessary
do_log() {
echo "$1"
[ -n "$2" ] && exit $2
}

# Routines for every operating system, as each of them handles EAs differently

do_darwin() {
# For now let's just assume that GNU coreutils are installed.
# It's by far much faster than it's perl or openssl alternatives.
PROGRAM=g${DIGEST}sum

case $ACTION in
	set)
	# We don't want to store the full pathname, only the filename
	BASENAME="`basename "$FILE"`"
	cd "`dirname "$FILE"`" || \
			do_log "ERROR: failed to cd into `dirname "$FILE"`! (FILE: $FILE)" 1

	echo "Setting user.checksum."$DIGEST" on "$FILE"..."
	xattr -w user.checksum."$DIGEST" "`$PROGRAM "$BASENAME"`" "$BASENAME" ||
			do_log "ERROR: failed to set EA for FILE $FILE!" 1

	# Go back to where we came from
	cd - > /dev/null
	;;

	check-set)
	CHECKSUM_S=`xattr -p user.checksum."$DIGEST" "$FILE" 2>/dev/null | cut -c-$LENGTH`
	if [ -z "$CHECKSUM_S" ]; then
		# No checksum found
		"$0" set "$FILE"
	else
		# Checksum found
		do_log "INFO: checksum found for $FILE, not setting a new checksum."
	fi
	;;

	get)
	xattr -l -p user.checksum."$DIGEST" "$FILE" || \
			do_log "ERROR: failed to get EA for FILE $FILE!" 1
	;;

	check)
	# Retrieve stored checksum
	CHECKSUM_S=`xattr -p user.checksum."$DIGEST" "$FILE" | cut -c-$LENGTH`

	# Bail out if there is no checksum to compare
	[ -z "$CHECKSUM_S" ] && do_log "ERROR: failed to get EA for FILE $FILE!" 1

	# Calculate current checksum
	CHECKSUM_C=`$PROGRAM "$FILE" | cut -c-$LENGTH` || \
			do_log "ERROR: failed to calculate checksum for FILE $FILE!" 1

	# Let's compare these two
	if [ "$CHECKSUM_S" = "$CHECKSUM_C" ]; then
		printf "FILE: $FILE - OK"
		[ "$DEBUG" = 1 ] && echo " ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)" || echo
	else
		printf "FILE: $FILE - FAILED"
		[ "$DEBUG" = 1 ] && echo " ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)" || echo
	fi
	;;

	*)
	print_usage
	exit 1
	;;
esac
}

do_freebsd() {
	echo TBD
}

do_linux() {
# GNU coreutils will be installed on most Linux distributions. It's also by far much
# faster than it's perl or openssl alternatives.
PROGRAM=${DIGEST}sum

case $ACTION in
	set)
	# We don't want to store the full pathname, only the filename
	BASENAME="`basename "$FILE"`"
	cd "`dirname "$FILE"`" || \
			do_log "ERROR: failed to cd into `dirname "$FILE"`! (FILE: $FILE)" 1

	echo "Setting user.checksum."$DIGEST" on "$FILE"..."
	setfattr --name user.checksum."$DIGEST" --value "`$PROGRAM "$BASENAME"`" "$BASENAME" || \
			do_log "ERROR: failed to set EA for FILE $FILE!" 1

	# Go back to where we came from
	cd - > /dev/null
	;;

	check-set)
	CHECKSUM_S=`getfattr --absolute-names --name user.checksum."$DIGEST" "$FILE" 2>/dev/null | cut -c-$LENGTH`
	if [ -z "$CHECKSUM_S" ]; then
		# No checksum found
		"$0" set "$FILE"
	else
		# Checksum found
		do_log "INFO: checksum found for $FILE, not setting a new checksum."
	fi
	;;

	get)
	# NOTE: If the designated EA is not set, getfattr may not return a non-exit code. This
	# has been fixed upstream but may not have been picked up by your distribution.
	# http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=520659
	# https://bugzilla.redhat.com/show_bug.cgi?id=660619
	getfattr --absolute-names --name user.checksum."$DIGEST" "$FILE" || \
			do_log "ERROR: failed to get EA for FILE $FILE!" 1
	;;

	check)
	# Retrieve stored checksum
	CHECKSUM_S=`getfattr --absolute-names --only-values --name user.checksum."$DIGEST" "$FILE" | cut -c-$LENGTH`

	# Bail out if there is no checksum to compare
	[ -z "$CHECKSUM_S" ] && do_log "ERROR: failed to get EA for FILE $FILE!" 1

	# Calculate current checksum
	CHECKSUM_C=`$PROGRAM "$FILE" | cut -c-$LENGTH` || \
			do_log "ERROR: failed to calculate checksum for FILE $FILE!" 1

	# Let's compare these two
	if [ "$CHECKSUM_S" = "$CHECKSUM_C" ]; then
		printf "FILE: $FILE - OK"
		[ "$DEBUG" = 1 ] && echo " ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)" || echo
	else
		printf "FILE: $FILE - FAILED"
		[ "$DEBUG" = 1 ] && echo " ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)" || echo
	fi
	;;
	
	*)
	print_usage
	exit 1
	;;
esac
}

do_solaris() {
	echo TBD
}

case $(uname -s) in
	Darwin)
	do_darwin
	;;

	FreeBSD)
	do_freebsd
	;;

	Linux)
	do_linux
	;;

	SunOS)
	do_solaris
	;;

	*)
	echo "We don't support $(uname -s), yet :-("
	;;
esac
