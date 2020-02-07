#!/bin/sh
#
# (c)2013 Christian Kujau <lists@nerdbynature.de>
#
# Create dm-crypt devices with different combinations of ciphers, modes, hash
# alorithms and key sizes.
#
# Preferably cryptsetup(8) would be able to parse /proc/crypto and generate a
# list of possible combinations, but this has not been implemented.
# See https://gitlab.com/cryptsetup/cryptsetup/issues/20 for that. Instead,
# we iterate through a list of more or less "common" choices and print out all
# valid (and invalid) combinations. The results can later be used by
# cryptsetup_benchmark.sh - so we don't benchmark invalid combinations.
#
# Something like this could do the trick:
# ciphers=$(grep -B6 -w cipher /proc/crypto | awk '/^name/ {print $3}' | sort)
#
# While the kernel should auto-load any needed modules, we can try to load any
# crypto related module before:
#
# $ find /lib/modules/$(uname -r)/ -type f -path "*kernel/crypto*" -printf "%f\n" \
#      | sed 's/\.ko$//' | while read a; do modprobe -v $a; done
#
# Test different cipher, mode and hash combinations. The output can be
# used by cryptsetup_benchmark.sh later on.
#

# unset me!
# DEBUG=echo

# RIP
die() {
	echo "$1"
	exit 2
}

if [ ! -b "$1" ]; then
	echo "Usage: $0 [device]"
	exit 1
else
	DEVICE="$1"
	    MD=test
	# cryptsetup is needed, for obvious reasons :)
	which cryptsetup > /dev/null || die "cryptsetup not found!"
fi


$DEBUG cryptsetup remove $MD 2>/dev/null
for c in aes anubis blowfish camellia cast5 cast6 cipher_null khazad salsa20 serpent twofish xtea; do
	for m in cbc ctr cts ecb lrw pcbc xts; do
		for h in plain crc32c ghash md4 md5 rmd128 rmd160 rmd256 rmd320 sha1 sha256 sha512 tgr192 wp512; do
			if [ $h = "plain" ]; then
				C=$c-$m-$h
			else
				C=$c-$m-essiv:$h
			fi
			for s in 128 256 384 448 512; do
				$DEBUG cryptsetup -c $C -s $s -d /dev/urandom create $MD "$DEVICE" 2>/dev/null
				if [ $? = 0 ]; then
					echo "Valid combination: cipher $C - size $s"
					$DEBUG cryptsetup status $MD

					# Remove the device again
					$DEBUG cryptsetup remove $MD || die "cryptsetup remove $MD failed"

					# Double-check if the device is really removed, bail out if not
					$DEBUG cryptsetup status $MD > /dev/null && die "device $MD is still online!"
				else
					echo "Invalid combination: cipher $C - size $s"
				fi
			done
		done
	done
done
