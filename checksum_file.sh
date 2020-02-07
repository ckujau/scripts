#!/bin/sh
#
# (c)2013 Christian Kujau <lists@nerdbynature.de>
#
# Generate checksums of files and store them via Extended Attributes.
#
# == Requirements ==
#  Darwin: /sbin/md5 or openssl
# FreeBSD: /sbin/{md5,sha{1,256,512}} and sysutils/pxattr
#   Linux: md5sum or sha{1,256,512}sum from GNU/coreutils
# Solaris: digest(1) and runat(1) from SUNWcsu
#	   We will also need at least an XPG4 or Korn shell on older Solaris
#	   systems, as older shells may not understand command substitution
#	   with parentheses, as required by POSIX.
#  NetBSD: cksum & {g,s}etextattr, should be included in src.
# OpenBSD: No extended attribute support since July 2005 (commit 9dd8235)
#
# Each operating system has its own routines for setting/getting EAs and also
# for calculating checksums. The only hardcoded value is the digest algorithm
# now.
#
# TODO:
# - Support other message digest algorithms (rmd160, sha3, ...)
# - Support other checksum toolsets (coreutils, openssl, rhash)
# - Rewrite file handling, process multiple files all at once.
# - Or rewrite this whole thing in Python, for portability's sake? (hashlib, os/xattr)
#
DIGEST="md5"			# md5, sha1, sha256, sha512

# Adjust if needed
PATH=/bin:/usr/bin:/sbin:/usr/local/bin:/opt/local/bin:/opt/csw/bin:/usr/sfw/bin

print_usage()
{
	echo "Usage: $(basename "$0") [get]       [file]"
	echo "       $(basename "$0") [set]       [file]"
	echo "       $(basename "$0") [get-set]   [file]"
	echo "       $(basename "$0") [check-set] [file]"
	echo "       $(basename "$0") [check]     [file]"
	echo "       $(basename "$0") [remove]    [file]"
	echo "       $(basename "$0") [test]"
	echo ""
	echo "   get-set - sets a new checksum if none is found, print checksum otherwise."
	echo " check-set - sets a new checksum if none is found, verify checksum otherwise."
}

if [ $# -ne 2 ] || [ ! -f "$2" ] && [ ! "$1" = "test" ]; then
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
	[ -n "$2" ] && exit "$2"
}

# CALC
_calc() {
case ${OS} in
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
	case ${DIGEST} in
		md5)
		md5 -q "$1"
		;;

		sha*)
		openssl dgst -${DIGEST} "$1" | awk '{print $NF}'
		;;
	esac
	;;

	FreeBSD)
	# FreeBSD 10 comes with: md5, sha1, sha256, sha512
	${DIGEST} -q "$1"
	;;

	NetBSD)
	# cksum should support all common algorithms.
	cksum -q -a ${DIGEST} "$1"
	;;

	Linux)
	# GNU/coreutils should be installed on most Linux distributions.
	# It's also by far much faster than its perl or openssl alternatives.
	${DIGEST}sum "$1" | awk '{print $1}'
	;;

	SunOS)
	# SUNWcsu should be available. If it's not, we'd have much bigger problems.
	digest -a ${DIGEST} "$1"
	;;

	*)
	do_log "We don't support ${OS}, yet :-(" 1
	;;
esac
}

# GET
_get() {
case ${OS} in
	Darwin)
	xattr  -p user.checksum.${DIGEST} "$1" 2>/dev/null | awk '{print $NF}'
	;;

	FreeBSD)
	pxattr -n user.checksum.${DIGEST} "$1" 2>/dev/null | awk '/user.checksum/ {print $NF}'
	;;

	NetBSD)
	getextattr -q user checksum.${DIGEST} "$1"
	;;

	Linux)
	# NOTE: If the designated EA is not set, getfattr may not return a non-zero
	# exit code. This has been fixed upstream but may not have been picked up
	# by your distribution.
	#
	# > getfattr should indicate missing xattrs via exit value
	# > https://bugs.debian.org/520659
	#
	# > getfattr does not return failure when designated attribute does not exist
	# > https://bugzilla.redhat.com/show_bug.cgi?id=660619
	#
	getfattr --only-values --name user.checksum.${DIGEST} -- "$1" 2>/dev/null | awk '/[a-z0-9]/ {print $1}'
	;;

	SunOS)
	runat "$1" cat user.checksum.${DIGEST} 2>/dev/null
	;;

	*)
	do_log "We don't support ${OS}, yet :-(" 1
	;;
esac
}

# SET
_set() {
echo "Setting user.checksum.${DIGEST} on ${1}..."
CHECKSUM_C=$(_calc "$1")

case ${OS} in
	Darwin)
	xattr -w user.checksum.${DIGEST} "${CHECKSUM_C}" "$1"
	;;

	FreeBSD)
	pxattr -n user.checksum.${DIGEST} -v "${CHECKSUM_C}" "$1"
	;;

	NetBSD)
	setextattr user checksum.${DIGEST} "${CHECKSUM_C}" "$1"
	;;

	Linux)
	setfattr --name user.checksum.${DIGEST} --value "${CHECKSUM_C}" -- "$1"
	;;

	SunOS)
	runat "$1" "echo ${CHECKSUM_C} > user.checksum.${DIGEST}"
	;;

	*)
	do_log "We don't support ${OS}, yet :-(" 1
	;;
esac
}

# Main routines, with switches for each OS
case ${ACTION} in
####### GET
	get)
	CHECKSUM_S=$(_get "$FILE")
	
	# Did we find a checksum?
	if [ -n "${CHECKSUM_S}" ]; then
		# Print out checksum
		echo "user.checksum.${DIGEST}: ${CHECKSUM_S}"
	else
		do_log "No user.checksum.${DIGEST} found for ${FILE}!" 1
	fi
	;;

####### SET
	set)
	_set "$FILE" || \
		do_log "ERROR: failed to set user.checksum.${DIGEST} for file ${FILE}!" 1
	;;

####### GET-SET)
	get-set)
	CHECKSUM_S=$(_get "$FILE")
	
	# Did we find a checksum?
	if [ -n "${CHECKSUM_S}" ]; then
		# Print out checksum
		echo "user.checksum.${DIGEST}: ${CHECKSUM_S}"
	else
		# Set checksum
		_set "$FILE"
	fi
	;;
		
####### CHECK-SET
	check-set)
	CHECKSUM_S=$(_get "$FILE")
	
	# Did we find a checksum?
	if [ -n "${CHECKSUM_S}" ]; then
		# Verify checksum
		$0 check "$FILE"				# Calling ourselves!
	else
		# Set checksum
		_set "$FILE"
	fi
	;;

####### CHECK
	check)
	CHECKSUM_C=$(_calc "$FILE")
	CHECKSUM_S=$(_get  "$FILE")

	# Bail out if there is no checksum to compare
	[ -z  "${CHECKSUM_C}" ] || [ -z "${CHECKSUM_S}" ] && \
		do_log "ERROR: failed to calculate/get the ${DIGEST} checksum for file ${FILE}!" 1

	# Compare checksums
	if [ "${CHECKSUM_S}" = "${CHECKSUM_C}" ]; then
		echo "FILE: ${FILE} - OK"
		true
	else
		echo "FILE: ${FILE} - FAILED"
		false
	fi
	;;

####### REMOVE
	remove)
	echo "Removing user.checksum.${DIGEST} from ${FILE}..."
	case ${OS} in
		Darwin)
		xattr -d user.checksum.${DIGEST} "$FILE"
		;;

		FreeBSD)
		pxattr -x user.checksum.${DIGEST} "$FILE"
		;;

		NetBSD)
		rmextattr user checksum.${DIGEST} "$FILE"
		;;

		Linux)
		setfattr --remove user.checksum.${DIGEST} -- "$FILE"
		;;

		SunOS)
		runat "$FILE" rm user.checksum.${DIGEST}
		;;

		*)
		do_log "We don't support ${OS}, yet :-(" 1
		;;
	esac
	;;

####### TEST
	test)
	# We need a temporary file, even on macOS
	TEMP=$(mktemp -p . 2>/dev/null || mktemp ./tmp.XXXXXXX 2>/dev/null)
	trap "rm -f $TEMP" EXIT INT TERM HUP

	if [ ! -f "$TEMP" ]; then
		do_log "Failed to create temporary file ${TEMP}!" 1
	else
		date > "${TEMP}"
	fi

	# More, and more elaborate tests needed.
	for action in get get-set check-set check remove remove check-set remove check; do
		echo "### ACTION: ${action}"
		$0 ${action} "${TEMP}"
		echo $? && echo
	done

	echo "### ACTION: set - alter - check"
	$0 set    "${TEMP}"
	echo "Modifying ${TEMP}..."
	echo . >> "${TEMP}"
	$0 check  "${TEMP}"
	echo "RC: $?"
	;;

####### HELP
	*)
	print_usage
	exit 1
	;;
esac
