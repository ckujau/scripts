#!/bin/sh
#
# (c)2019 Christian Kujau <lists@nerdbynature.de>
# Read-only Benchmark for FreeBSD/geli.
#
CIPHERS="aes-xts aes-cbc blowfish-cbc camellia-cbc 3des-cbc"	# See geli(8)
   PROG=$(basename $0)
set -e

_help() {
echo "Usage:    ${PROG} [devicename] [size(MB)] [runs]"
echo "          ${PROG} report [out.txt]"
echo ""
echo "Example:  ${PROG} ada0p2 5 | tee out.txt"
echo "          ${PROG} report out.txt"
}

_benchmark() {
 DEV="$1"
SIZE="$2"
 NUM="$3"


# RAW
for i in $(seq 1 "${NUM}"); do
	printf "MODE: raw     I: $i\t"
	dd if=/dev/"${DEV}"  of=/dev/null bs=1k count="${SIZE}"k conv=sync 2>&1 | grep bytes
done

# ENCRYPTED
for c in ${CIPHERS}; do
	geli onetime -e "${c}" /dev/"${DEV}"

	# Repeat NUM times...
	for i in $(seq 1 "${NUM}"); do
		printf "MODE: ${c} I: $i\t"
		dd if=/dev/"${DEV}.eli" of=/dev/null bs=1k count="${SIZE}"k conv=sync 2>&1 | grep bytes
	done

	geli detach /dev/"${DEV}.eli"
done
}

case $1 in
	report)
	if [ -f "$2" ]; then
		for c in $(awk '/MODE:/ {print $2}' "$2" | uniq); do
			NUM=$(grep -c "MODE: $c" "$2")
			printf "${c}  \t"
			awk "/MODE: ${c}/ {print \$9, \$11, \$2}" "$2" | sed 's/(//' | \
 				awk "{time+=\$1} {speed+=\$2} END {print time/${NUM}, \"sec /\", speed/${NUM}/1024/1024, \"MB/s\"}"
		done
	else
		_help
	fi
	;;

	*)
	if [ -c /dev/"$1" ] && [ "$2" -gt 0 ] && [ "$3" -gt 0 ]; then
		_benchmark "${1}" "${2}" "${3}"
	else
		_help
	fi
	;;
esac
