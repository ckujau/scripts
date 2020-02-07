#!/bin/sh
#
# (c)2015 Christian Kujau <lists@nerdbynature.de>
#
# Benchmark various checksum programs
#
# Example:
# $ dd if=/dev/urandom bs=1M count=200 | pv > test.img 
# $ ./test-digests.sh test.img 10 | tee out.log
#
# Print results with:
# $ egrep -v '^RHash|calculated|test.img' out.log | grep MBps | sort -rnk8
# $ grep ^TEST out.log | egrep -v 'rhash_benchmark|SKIPPED'   | sort -nk7
#
if [ -f "$1" ]; then
	FILE="$1"
	RUNS=${2:-1}
else
	echo "Usage: $(basename "$0") [file] [n]"
	exit 1
fi

# unset me!
# DEBUG=echo

get_time() {
	TEST="$1"
	# Only one run for rhash_benchmark
	[ "$TEST" = "rhash_benchmark" ] && n=1 || n=$RUNS
	shift

	TIME_A=$(date +%s)
	for i in $(seq 1 "$n"); do
		$DEBUG $@
	done
	TIME_B=$(date +%s)
	echo "TEST: $TEST / DIGEST: $d / $(echo "$TIME_B" - "$TIME_A" | bc -l) seconds over $n runs"
}


# rhash benchmarks
# NOTE: just for kicks, we'll test SHA3 too
for d in md5 sha1 sha224 sha256 sha384 sha512 ripemd160 sha3-224 sha3-256 sha3-384 sha3-512; do
	get_time rhash_benchmark rhash -B --"$d"
done

# MAIN LOOP
for d in md5 sha1 sha224 sha256 sha384 sha512 ripemd160; do
	get_time rhash rhash --"$d" --bsd "$FILE"
	get_time openssl openssl dgst -"$d" "$FILE"

	# GNU/coreutils doesn't understand RIPEMD160
	if [ ! $d = "ripemd160" ]; then
		get_time coreutils "$d"sum "$FILE"
	else
		echo "TEST: coreutils / DIGEST: $d / SKIPPED"
	fi

	# Perl's shasum only understands SHA variants.
	# FIXME: that's not true, at all -- we could just use the installed
	# modules directly, like:
	# > perl -le 'use Digest::SHA  qw(sha1_hex);     print     sha1_hex(<>);'
	# > perl -le 'use Digest::MD5  qw(md5_hex);      print      md5_hex(<>);'
	# > perl -le 'use Digest::SHA  qw(sha256_hex);   print   sha256_hex(<>);'
	# > perl -le 'use Digest::SHA3 qw(sha3_256_hex); print sha3_256_hex(<>);'
	case $d in
		sha*)
		# Remove the "sha" prefix from the digest names
		dp=${d##sha}
		get_time perl shasum -a "$dp" "$FILE"
		;;

		*)
		echo "TEST: perl / DIGEST: $d / SKIPPED"
		;;
	esac
	echo
done
