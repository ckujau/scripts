#!/bin/sh
#
# (c)2014 Christian Kujau <lists@nerdbynature.de>
#
# Attempts to open an SSH connection with different Ciphers, MACs and
# Key Exchange Algorithms. The output can be fed to ssh-performance.sh later on.
#
# Note: Starting with OpenSSH 6.3, we can use "ssh -Q" to enumerate all known 
# ciphers, MAC and key exchange algorithms, so this script is kinda obsolete now.
#
# Run with:
# ./ssh-features.sh dummy@host0 2>&1 | tee ssh-eval.log
#

# Find out which ciphers are supported in _our_ version. And we do this by looking up its manpage...is
# there really no other way? (Apart from running strings(1) on the SSH binary)
CIPHERS=$(man ssh_config | grep -A5  aes128-ctr,   | fgrep , | xargs echo | sed 's/,/ /g')
   MACS=$(man ssh_config | grep -A15 MACs          | egrep '  [hu]mac' | xargs echo | sed 's/,/ /g')
    KEX=$(man ssh_config | grep -A10 KexAlgorithms | egrep '(ecdh|diffie|curve)' | xargs echo | sed 's/,/ /g')

ssh -V 2>&1 | cat

echo "Ciphers (`echo $CIPHERS | wc -w`):"
echo $CIPHERS
echo

echo "MACs (`echo $MACS | wc -w`):"
echo $MACS
echo

echo "KexAlgorithms (`echo $KEX | wc -w`):"
echo $KEX
echo

if [ -z "$1" ]; then
	echo "Usage: $0 [user@][host]"
	exit 1
else
	host="$1"
fi

ssh -v "$host" true 2>&1 | egrep 'Local version|Remote proto'
echo
for c in $CIPHERS; do
	for m in $MACS; do
		for k in $KEX; do
			printf "cipher: $c mac: $m kex: $k   "
			ssh -o Ciphers="$c" -o MACs="$m" -o KexAlgorithms="$k" "$host" true 2>/dev/null
			echo "exit: $?"
		done
	done
done
