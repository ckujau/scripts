#!/bin/sh
#
# (C)2013, lists@nerdbynature.de
# dm-crypt tester
#

# DEBUG=echo

if [ ! -b "$1" ]; then
	echo "Usage: $0 [device]"
	exit 1
else
	DEVICE="$1"
	    MD=test
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
				$DEBUG cryptsetup -c $C -s $s -d /dev/urandom create $MD $DEVICE 2>/dev/null
				if [ $? = 0 ]; then
					echo "Valid combination: cipher $C - size $s"
					$DEBUG cryptsetup status $MD
				else
					echo "Invalid combination: cipher $C - size $s"
				fi
				$DEBUG cryptsetup remove $MD 2>/dev/null
				sleep 1
			done
		done
	done
done
