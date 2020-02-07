#!/bin/sh
#
# (c)2014 Christian Kujau <lists@nerdbynature.de>
# Test various password generators and password checkers
#
# Needs the following programs installed:
# cracklib-runtime, passwdqc, pwgen, apg, gpw, makepasswd, openssl, GNU/parallel
#

# Password length and number of passwords required
if [ -z "$1" ]; then
	echo "Usage: $(basename "$0") [length] [num]"
	exit 1
else
	LEN="$1"
	NUM="$2"

	# See the comment for r_pwqgen below
	if [ "$LEN" -gt 22 ]; then
		echo "WARNING: \"length\" is greater than 22, results for pwqgen may not be correct!"
	fi
	
	# See the comment for r_openssl below
	if [ "$LEN" -gt 64 ]; then
		echo "WARNING: \"length\" is greater than 64, results for openssl may not be correct!"
	fi
fi

stats() {
# arguments: FAILED, NUM, TYPE, TIME_E, TIME_S
echo "$FAILED passwords ($(echo "scale=2; $FAILED / $NUM * 100" | bc -l)%) failed for $c, runtime: $(expr "$TIME_E" - "$TIME_S") seconds."
}

# Password checkers
r_cracklib() {
parallel --pipe /usr/sbin/cracklib-check 2>/dev/null | fgrep -c -v ': OK'
}

r_pwqcheck() {
parallel --pipe pwqcheck -1 --multi 2>/dev/null | fgrep -c -v 'OK:'
}

# Password generators
r_pwgen() {
pwgen -s -1 "$LEN" "$NUM"
}

#
# OK, pwqgen is somewhat special: while all other programs can generate (a
# certain number of) passwords of a certain length, pwqgen generates only one
# password of certain randomness (in bits). With random=85 (the highest
# setting), we're only guaranteed to get a password of at least 22 characters:
#
# $ for a in {1..10000}; do pwqgen random=85; done | awk '{print length}' | sort -n  | head -1
# => 22
#
# The absolute maximum length seems to be 35 characters:
#
# $ for a in {1..10000}; do pwqgen random=85; done | awk '{print length}' | sort -rn | head -1
# => 35
#
r_pwqgen() {
# The following is good enough for passwords of length 22 characters and below:
for a in $(seq 1 "$NUM"); do
	pwqgen random=85
done | cut -c-"$LEN" | egrep -o "^.{$LEN}$"

# The following would be the correct solution, but also takes much longer:
# i=0; while [ $i -lt $NUM ]; do
#	pwqgen random=85 | cut -c-"$LEN" | egrep -o "^.{$LEN}$" && i=$((i+1))
# done
}

r_apg() {
apg -a 1 -m "$LEN" -x "$LEN" -n "$NUM"
}

r_gpw() {
# gpw: Password Generator
# https://www.multicians.org/thvv/tvvtools.html#gpw
#  USAGE: gpw [npasswds] [pwlength<100]
gpw "$NUM" "$LEN"
}

r_makepasswd() {
# There are actually two versions available:
#
# The Debian version of makepasswd resides in the "whois" package:
# > whois: Why does it include mkpasswd?
# > https://bugs.debian.org/116260
#
# > Fedora / mkpasswd
# > https://koji.fedoraproject.org/koji/packageinfo?packageID=17537
#
# makepasswd --chars=$LEN --count=$NUM				# Debian
makepasswd -l "$LEN" -n "$NUM"					# Fedora
}

r_urandom() {
for a in $(seq 1 "$NUM"); do
	tr -dc A-Za-z0-9_ < /dev/urandom | head -c "$LEN" | xargs
done
}

r_openssl() {
#
# While openssl(1) is not strictly a password generator, it can emit (pseudo-)random
# strings of text. But, as pwqgen above, it has the same limitation: it generates only
# one certain number of random bytes of unspecified length. We're using base64 encoding
# here, to generate printable text - but this means that the last (two) characters are
# two equal signs ("=="). Using -hex would limit our charset too much though. Also,
# since we're reading line-by-line, we have an upper limit of 64 characters.
#
for a in $(seq 1 "$NUM"); do
	openssl rand -base64 64 | head -1
done | sed 's/.=$//' | cut -c-"$LEN"
}

# main loop
for c in cracklib pwqcheck; do
	for g in pwgen pwqgen apg gpw makepasswd openssl urandom; do
		printf "%10s - %s" $g
		TIME_S=$(date +%s)
		FAILED=$(r_$g | r_$c)
		TIME_E=$(date +%s)
		stats "$FAILED" "$NUM" $c "$TIME_E" "$TIME_S"
	done
	echo
done
