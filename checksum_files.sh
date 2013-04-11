#!/bin/sh
#
# (c) 2013, Christian Kujau <lists@nerdbynature.de>
#
# Generate checksums of files and store them via
# xattr (Extended Attributes)
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

# It's really hard to find a delimiter to get _only_ the checksum from openssl(1).
# Think of filenames like "test with space and equal sign=).txt" and look at
# openssl's default output. Our best bet is to look at the N last characters,
# where N depends on the digest used:
LENGTH=$(echo test | openssl $DIGEST | awk '{printf $2}' | wc --chars)

print_usage()
{
	echo "Usage: `basename $0` [set]   [file1] [file2] ... [fileN]"
	echo "       `basename $0` [get]   [file1] [file2] ... [fileN]"
	echo "       `basename $0` [check] [file1] [file2] ... [fileN]"
}

if [ -z "$2" ]; then
	print_usage
else
	ACTION="$1"
	shift 1
	FILES="$@"
fi

do_log() {
echo "$1"

# Continue with the next file
[ "$2" = 1 ] && continue
}

# Routines for every operating system, so we don't have to switch
# while working on FILES

do_darwin() {
# For now let's just assume that GNU coreutils are installed.
# It's by far much faster than it's perl or openssl alternatives.
PROGRAM=g${DIGEST}sum

for f in $FILES; do
	case $ACTION in
		set)
		# We don't want to store the full pathname, only the filename
		BASENAME="`basename "$f"`"
		cd "`dirname "$f"`" || do_log "ERROR: failed to cd into `dirname "$f"`! (FILE: $f)" 1

		xattr -w user.checksum."$DIGEST" "`$PROGRAM "$BASENAME"`" "$BASENAME" ||
			do_log "ERROR: failed to set EA for FILE $f!" 1

		# Go back to where we came from
		cd - > /dev/null
		;;

		get)
		xattr -l -p user.checksum."$DIGEST" "$f" || \
			do_log "ERROR: failed to get EA for FILE $f!" 1
		;;

		check)
		# Retrieve stored checksum
		CHECKSUM_S=`xattr -p user.checksum."$DIGEST" "$f" | cut -c-$LENGTH` || \
			do_log "ERROR: failed to get EA for FILE $f!" 1

		# Calculate current checksum
		CHECKSUM_C=`$PROGRAM "$f" | cut -c-$LENGTH` || \
			do_log "ERROR: failed to calculate checksum for FILE $f!" 1

		# Let's compare these two
		if [ "$CHECKSUM_S" = "$CHECKSUM_C" ]; then
			printf "FILE: $f - OK"
			[ "$DEBUG" = 1 ] && echo " ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)" || echo
		else
			printf "FILE: $f - FAILED"
			[ "$DEBUG" = 1 ] && echo " ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)" || echo
		fi
		;;
	
		*)
		print_usage
		exit 1
		;;
	esac
done
}

do_freebsd() {
	echo TBD
}

do_linux() {
# GNU coreutils will installed on most Linux distributions. It's also by far much
# faster than it's perl or openssl alternatives.
PROGRAM=${DIGEST}sum

for f in $FILES; do
	case $ACTION in
		set)
		# We don't want to store the full pathname, only the filename
		BASENAME="`basename "$f"`"
		cd "`dirname "$f"`" || do_log "ERROR: failed to cd into `dirname "$f"`! (FILE: $f)" 1

		setfattr --name user.checksum."$DIGEST" --value "`$PROGRAM "$BASENAME"`" "$BASENAME" || \
			do_log "ERROR: failed to set EA for FILE $f!" 1

		# Go back to where we came from
		cd - > /dev/null
		;;

		get)
		# NOTE: If the designated EA is not set, getfattr may not return a non-exit code. This
		# has been fixed upstream but may not have been picked up by your distribution.
		# http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=520659
		# https://bugzilla.redhat.com/show_bug.cgi?id=660619
		getfattr --absolute-names --name user.checksum."$DIGEST" "$f" || \
			do_log "ERROR: failed to get EA for FILE $f!" 1
		;;

		check)
		# Retrieve stored checksum
		CHECKSUM_S=`getfattr --absolute-names --only-values --name user.checksum."$DIGEST" "$f" | cut -c-$LENGTH` || \
			do_log "ERROR: failed to get EA for FILE $f!" 1

		# Calculate current checksum
		CHECKSUM_C=`$PROGRAM "$f" | cut -c-$LENGTH` || \
			do_log "ERROR: failed to calculate checksum for FILE $f!" 1

		# Let's compare these two
		if [ "$CHECKSUM_S" = "$CHECKSUM_C" ]; then
			printf "FILE: $f - OK"
			[ "$DEBUG" = 1 ] && echo " ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)" || echo
		else
			printf "FILE: $f - FAILED"
			[ "$DEBUG" = 1 ] && echo " ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)" || echo
		fi
		;;
	
		*)
		print_usage
		exit 1
		;;
	esac
done
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
