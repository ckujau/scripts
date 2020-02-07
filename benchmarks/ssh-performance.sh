#!/bin/sh
#
# (c)2014 Christian Kujau <lists@nerdbynature.de>
#
# Poor wo/man's SSH benchmark. Inspired by:
# > OpenSSH default/preferred ciphers, hash, etc for SSH2
# > https://security.stackexchange.com/a/26074
#
# Compare with:
# > OpenBSD: cipher-speed.sh
# > https://anongit.mindrot.org/openssh.git/tree/regress/cipher-speed.sh
#
_help() {
	echo "Usage: $(basename $0) run    [user@][host] [size-in-MB] [runs] | tee report.out"
	echo "       $(basename $0) report [report.out]  [top]"
	echo "       $(basename $0) worst  [report.out]  [top]"
	echo
	echo "Note: Cipher, MAC and Kex algorithms can also be controlled by"
	echo "      the CIPHER, MAC and KEX environment variables."
	exit 1
}

#
# Benchmark
#
_run() {
# We'll need a temporary file, but remove it later on.
TEMP=$(mktemp)
trap 'rm -f "$TEMP"; exit' EXIT INT TERM HUP

# Enumerate all known ciphers, MAC and key exchange algorithms.
# Available since OpenSSH 6.3
#
# === Distribution support ================
# | Debian/wheezy-backports  || OpenSSH 6.6
# | Ubuntu/14.04             || OpenSSH 6.6
# | Fedora/20                || OpenSSH 6.3
# | openSUSE/13.2            || OpenSSH 6.6
#
CIPHER="${CIPHER:-$(ssh -Q cipher)}"
   MAC="${MAC:-$(ssh -Q mac)}"
   KEX="${KEX:-$(ssh -Q kex)}"

# Possible combinations
COMB=$(expr $(echo $CIPHER | awk '{print NF}') \* $(echo $MAC | awk '{print NF}') \* $(echo $KEX | awk '{print NF}'))

# Initialize combination counter
n=1

# Ready, set, Go! 
for c in $CIPHER; do
  for m in $MAC; do
    for k in $KEX; do

      # Initialize run counter
      r=1

      printf "$n/$COMB cipher: $c \t mac: $m \t kex: $k - "
#     [ $RUNS -lt 10 ] && printf " "				# Formatting quirk...

      a=$(date +%s)
      while [ $r -le $RUNS ]; do
        printf "$r\b" >&2					# We don't need this on stdout

        dd if=/dev/zero bs=1024k count="$SIZE" 2>/dev/null | \
          ssh -T -o CheckHostIP=no -o StrictHostKeyChecking=no \
            -o Ciphers="$c" -o MACs="$m" -o KexAlgorithms="$k" "$HOST" "cat > /dev/null" 2>"$TEMP"

        # Did we manage to establish a connection?
        if [ ! $? = 0 ]; then
          ERR=1
          echo "n/a ($(cut -c-40 "$TEMP"))"
          break
        fi
        r=$((r+1))
      done

      # Calculate the average time for one run; reset the error counter.
      b=$(date +%s)
      d=$(echo \( $b - $a \) / $RUNS | bc)
      [ -z "$ERR" ] && echo "$d seconds avg." || unset ERR
      n=$((n+1))
    done
  done
done
}

#
# Reports
#
_report() {
echo "### Top-$TOP overall"
grep seconds "$FILE" | sort $REVERSE -nk9 | head -$TOP
echo

echo "### Fastest cipher"
awk '/seconds/ {print $3, $9, "seconds"}' "$FILE" | sort $REVERSE -nk2 | head -$TOP | uniq -c
echo

echo "### Fastest MAC"
awk '/seconds/ {print $5, $9, "seconds"}' "$FILE" | sort $REVERSE -nk2 | head -$TOP | uniq -c
echo

echo "### Fastest Kex"
awk '/seconds/ {print $7, $9, "seconds"}' "$FILE" | sort $REVERSE -nk2 | head -$TOP | uniq -c
echo

echo "### Top-$TOP for each cipher"
for c in $(awk '/seconds/ {print $3}' "$FILE" | sort -u); do
	echo "### Cipher: $c"
	fgrep seconds "$FILE" | grep "$c" | sort $REVERSE -nk9 | head -$TOP
	echo
done

echo "### Top-$TOP for each MAC"
for m in $(awk '/seconds/ {print $5}' "$FILE" | sort -u); do
	echo "### MAC: $m"
	fgrep seconds "$FILE" | grep "$m" | sort $REVERSE -nk9 | head -$TOP
	echo
done

echo "### Top-$TOP for each Kex"
for k in $(awk '/seconds/ {print $7}' "$FILE" | sort -u); do
	echo "### Kex: $k"
	fgrep seconds "$FILE" | grep "$k" | sort $REVERSE -nk9 | head -$TOP
	echo
done
}

# Pick your poison.
case $1 in
	run)
	if [ $# -ne 4 ]; then
		_help
	else
		HOST="$2"
		SIZE="$3"
		RUNS="$4"
		_run
	fi
	;;

	report|worst)
	if [ ! -f "$2" ]; then
		_help
	else
		[ $1 = "worst" ] && REVERSE="-r" # Hall of Shame
		FILE="$2"
		 TOP=${3:-5}
		_report
	fi
	;;

	*)
	_help
	;;
esac
