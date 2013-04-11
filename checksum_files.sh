#!/bin/sh
#
# (c) 2013, Christian Kujau <lists@nerdbynature.de>
#
# Generate checksums of files and store them via
# xattr (Extended Attributes)
#
# Notes:
# * We could use "shasum", which lets us choose the (SHA based) digest. However,
#   "shasum" is a Perl script and preliminary tests have shown that it's
#   twice as slow as "sha1sum" (a C binary) from the coreutils package.
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

# Continue or Exit?
case $2 in
	1) continue
	;;
	
	2) exit 2
	;;
esac
}

# Routines for every operating system, so we don't have to switch
# while working on FILES

do_darwin() {
	echo TBD
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
		getfattr --absolute-names --name user.checksum."$DIGEST" "$f" || do_log 
		;;

		check)
		# Retrieve stored checksum
		CHECKSUM_S=`getfattr --absolute-names --only-values --name user.checksum."$DIGEST" "$f" | cut -c-$LENGTH`

		# Calculate current checksum
		CHECKSUM_C=`$PROGRAM "$f" | cut -c-$LENGTH`

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
