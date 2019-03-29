#!/bin/sh
#
# (c)2014 Christian Kujau <lists@nerdbynature.de>
# Poor wo/man's SSH benchmark. Inspired by:
# > OpenSSH default/preferred ciphers, hash, etc for SSH2
# > http://security.stackexchange.com/questions/25662/openssh-default-preferred-ciphers-hash-etc-for-ssh2
#
# Compare with:
# > OpenBSD: cipher-speed.sh
# > https://anongit.mindrot.org/openssh.git/tree/regress/cipher-speed.sh
#

_help() {
	echo "Usage: $(basename $0) run    [user@][host] [size-in-MB] [runs]"
	echo "       $(basename $0) report [performance.log] [top]"
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
# Available since OpenSSH 6.3 / http://www.openssh.com/txt/release-6.3
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

      printf "$n/$COMB - cipher: $c \t mac: $m \t kex: $k - "
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
      [ -z "$ERR" ] && printf "$d seconds avg.\n" || unset ERR
      n=$((n+1))
    done
  done
done
}

_filter() {
#
# FIXME: is this still needed?
#
# The progress meter messed up our log file and we'll remove the control
# characters again with this ugly sed string.
# Or, use cat-v:  ... | cat -v | sed 's/1\^H.*\^H//' 
#
#	grep seconds "$1" | sed 's/[0-9]\x08//g;s/\x08//'
	grep seconds "$1"
}

#
# Reports
#
_report() {
echo "### Top-$TOP overall"
_filter "$FILE" | sort -rnk10 | tail -$TOP
echo

echo "### Fastest cipher"
_filter "$FILE" | awk '/seconds/ {print $4, $10, "seconds"}' | sort -rnk2 | tail -$TOP
echo

echo "### Fastest MAC"
_filter "$FILE" | awk '/seconds/ {print $6, $10, "seconds"}' | sort -rnk2 | tail -$TOP
echo

echo "### Fastest Kex"
_filter "$FILE" | awk '/seconds/ {print $8, $10, "seconds"}' | sort -rnk2 | tail -$TOP
echo

echo "### Top-$TOP for each cipher"
for c in $(_filter "$FILE" | awk '/seconds/ {print $4}' | sort -u); do
	echo "### Cipher: $c"
	_filter "$FILE" | grep "$c" | sort -rnk10 | tail -$TOP
	echo
done

echo "### Top-$TOP for each MAC"
for m in $(_filter "$FILE" | awk '/seconds/ {print $6}' | sort -u); do
	echo "### MAC: $m"
	_filter "$FILE" | grep "$m" | sort -rnk10 | tail -$TOP
	echo
done

echo "### Top-$TOP for each Kex"
for k in $(_filter "$FILE" | awk '/seconds/ {print $8}' | sort -u); do
	echo "### Kex: $k"
	_filter "$FILE" | grep "$k" | sort -rnk10 | tail -$TOP
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

	report)
	if [ ! -f "$2" ]; then
		_help
	else
		FILE="$2"
		 TOP=${3:-5}
		_report
	fi
	;;

	*)
	_help
	;;
esac
