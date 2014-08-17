#!/bin/sh
#
# (c) christian@nerdbynature.de
# Poor wo/man's SSH benchmark
#
# Run with:
# ./ssh-performance.sh ssh-eval.log dummy@host 100 2>&1 | tee ssh-performance.log
#
# The ssh-eval.log must be created with ssh-features.sh.
#
if [ ! -f "$1" -o $# -ne 3 ]; then
	echo "Usage: $(basename $0) [ssh-eval.log] [user@][host] [size-in-MB]"
	exit 1
else
	FILE="$1"
	HOST="$2"
	SIZE="$3"
fi

# Counter
i=1

# How many permutations to test
num=$(grep -c 'exit: 0' "$FILE")
awk '/exit:\ 0/ {print $2,$4,$6}' "$FILE" | while read c m k; do
	a=`date +%s`
	printf "$i/$num - cipher: $c mac: $m kex: $k - "
	dd if=/dev/zero bs=1024k count="$SIZE" 2>/dev/null | \
		ssh -T -o Ciphers="$c" -o MACs="$m" -o KexAlgorithms="$k" "$HOST" "cat > /dev/null"
	b=`date +%s`
	echo "`expr $b - $a` seconds"
	i=$((i+1))
done
