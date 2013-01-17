#!/bin/sh
#
# (C)2013, lists@nerdbynature.de
# Poor man's dm-crypt benchmark
#

# DEBUG=echo

if [ ! -b "$1" -o -z "$4" ]; then
	echo "Usage: $0 [device] [cipher] [size] [runs]"
	echo "Examples:"
	echo "`basename $0` /dev/sdu1 aes-cbc-plain 128"
	echo "`basename $0` /dev/sdu1 aes-cbc-essiv:sha256 448"
	exit 1
else
	DEVICE="$1"
	CIPHER="$2"
	  SIZE="$3"
	  RUNS="$4"
	    MD=test
fi

cryptsetup remove $MD 2>/dev/null
$DEBUG cryptsetup -c $CIPHER -s $SIZE -d /dev/urandom create $MD $DEVICE || exit 1
## $DEBUG cryptsetup status $MD || exit 1
printf "$CIPHER / $SIZE : "
TIME_S=`date +%s`
i=0
while [ $i -lt $RUNS ]; do
##	printf "$i "
	$DEBUG sysctl -qw vm.drop_caches=3
	$DEBUG dd if=/dev/mapper/$MD of=/dev/null bs=1M 2>/dev/null
	i=$((i+1))
done
TIME_E=`date +%s`
expr $TIME_E - $TIME_S
cryptsetup remove $MD
