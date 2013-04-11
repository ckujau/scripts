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
# TODO: Make script portable accross operating systems
#
DIGEST="sha256"			# sha1, sha256, sha512

# Adjust if needed
PATH=/bin:/usr/bin:/opt/csw/bin:/usr/sfw/bin

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

# Routines for every operating system, so we don't have to use switches while
# working on FILES
do_linux() {
for f in $FILES; do
#	echo "ACTION: $ACTION FILE: $f"
	case $ACTION in
		set)
		BASENAME="`basename "$f"`"
		echo setfattr --name user.checksum."$DIGEST" --value "`openssl dgst -$DIGEST "$f"`" "$f"
		;;

		get)
		getfattr --name user.checksum."$DIGEST" "$f"
		;;

		check)
		# Retrieve stored checksum
		CHECKSUM_S=`getfattr --only-values --name user.checksum."$DIGEST" "$f"`

		# Boah, did that get ugly. Let's try better next time, for now we have:
		CHECKSUM_C=`openssl dgst -$DIGEST "$f" | rev | cut -c-$LENGTH | rev`

		# Let's compare these two
		if [ "$CHECKSUM_S" = "$CHECKSUM_C" ]; then
			echo "FILE: $f - OK"
		else
			echo "FILE: $f - FAILED ($DIGEST STORED: $CHECKSUM_S  CALCULATED: $CHECKSUM_C)"
		fi
		;;
	
		*)
		print_usage
		exit 1
		;;
	esac
done
}

case $(uname -s) in
	Darwin)
	do_darwin
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
