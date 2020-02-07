#!/bin/ksh -e
#
# (c)2019 Christian Kujau <lists@nerdbynature.de>
# Benchmark for NetBSD/CGD. We'd need something similar for other BSD
# variants too.
#
CIPHERS="aes-cbc aes-xts 3des-cbc blowfish-cbc"	# See cgd(4)
CGD=cgd3

# unset me!
# DEBUG="count=1"				# Read only one byte, for testing.

# Short circuit into report mode
if [ "$1" = "report" ] && [ -f "$2" ]; then
	for c in $(awk '/MODE:/ {print $2}' "$2" | uniq); do
		NUM=$(grep -c "MODE: $c" "$2")
		printf "$c  \t"
		awk "/MODE: $c/ {print \$9, \$11, \$2}" "$2" | sed 's/(//' | \
 			awk "{time+=\$1} {speed+=\$2} END {print time/${NUM}, \"sec /\", speed/${NUM}/1024/1024, \"MB/s\"}"
	done
	exit $?
fi

# FIXME: Do we want more options on the command line?
if [ ! -c /dev/r"${1}" ] || [ -z "$2" ]; then
	echo "Usage:    $(basename "$0") [devicename] [runs]"
	echo "          $(basename "$0") report [out.txt]"
	echo ""
	echo "Example:  $(basename "$0") wd0b 5 | tee out.txt"
	echo "          $(basename "$0") report out.txt"
	exit 1
else
	# Note: in BSD, we will use character devices, not block devices. However,
	# for setting up the CGD, a block device is indeed required. See also:
	# https://www.freebsd.org/doc/en/books/arch-handbook/driverbasics-block.html
	# https://www.netbsd.org/docs/kernel/pseudo/
	DEV="$1"
	NUM="$2"
	PRM=$(mktemp -d)		# Where to store our parameter files.
fi

# RAW
for i in $(seq 1 "$NUM"); do
	printf "MODE: raw     I: $i\t"
	dd if=/dev/r"${DEV}"  of=/dev/null bs=1k "$DEBUG" conv=sync 2>&1 | grep bytes
done

# CGD
for c in $CIPHERS; do
	cgdconfig -g -k urandomkey -o "${PRM}"/test_"${c}" "$c"
	cgdconfig ${CGD} /dev/"${DEV}"  "${PRM}"/test_"${c}"

	# Repeat NUM times...
	for i in $(seq 1 "$NUM"); do
		printf "MODE: $c I: $i\t"
		dd if=/dev/r${CGD}a of=/dev/null bs=1k "$DEBUG" conv=sync 2>&1 | grep bytes
	done

	cgdconfig -u /dev/${CGD}a
	rm -f "${PRM}"/test_"${c}"
done
rmdir "${PRM}"
