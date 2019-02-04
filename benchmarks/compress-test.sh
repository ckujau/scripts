#!/usr/bin/env bash
#
# (c)2011 Christian Kujau <lists@nerdbynature.de>
#
# Compress a file with different programs and see how long it took to do this.
#
# Links:
#
# Squash Compression Benchmark
# https://quixdb.github.io/squash-benchmark/
#
# Large Text Compression Benchmark
# http://mattmahoney.net/dc/text.html
#
# Lzturbo library: world's fastest compression library
# https://sites.google.com/site/powturbo/home/benchmark
#
# Packbench
# https://martin-steigerwald.de/computer/programme/packbench/
#
PATH=/usr/local/bin:/usr/bin:/bin
PROGRAMS=${PROGRAMS:-gzip pigz bzip2 pbzip2 xz pxz lzma plzma brotli zstd pzstd}
MODES=${MODES:-9c 1c dc}			# {1..9}c for   compression
						#      dc for decompression
_help() {
	echo "Usage: $(basename $0) [-n runs] [-f file]"
	echo "       $(basename $0) [-r results]"
	echo
	echo "Available environment variables that can be set:"
	echo "PROGRAMS (default: $PROGRAMS)"
	echo "   MODES (default: $MODES)"
	echo
	exit 1
}

_report() {
	echo "### Fastest compressor:"
	grep -v /dc ${REPORT} | sort -nk3
	echo

	echo "### Smallest size:"
	grep -v /dc ${REPORT} | sort -nrk6
	echo

	echo "### Fastest decompressor:"
	grep    /dc ${REPORT} | sort -nk3
	echo
	exit $?
}

# Gather options
while getopts "n:f:r:" opt; do
	case $opt in
	n)
	runs=${OPTARG}
	;;

	f)
	FILE=${OPTARG}
	;;

	r)
	REPORT=${OPTARG}
	;;

	*)
	_help
	;;
	esac
done

# Are we in report mode?
[ -f "${REPORT}" ] && _report					# The "" are important here!

# Default to one run
RUNS=${runs:-1}

# Read file into RAM once
[ -f ${FILE} ] && cat ${FILE} > /dev/null || _help

# Iterate through all modes, programs
for m in $MODES; do
	for p in $PROGRAMS; do
		if ! which ${p} > /dev/null 2>&1; then
			echo "### Program ${p} not found - skipping."
			continue
		fi
		SIZE1=$(ls -go ${FILE} | awk '{print $3}')
		START=$(date +%s)

		# If all programs had the same options, we would not have to do this.
		case $p in
			brotli|bro)
			if [ $m = "dc" ]; then
				_cmd(){ ${p} -${m} ${FILE}.${p}    > /dev/null; }
			else
				qual=$(echo $m | sed 's/c$//')				# Sigh...
				_cmd(){ ${p} -q ${qual} -c ${FILE}  > ${FILE}.${p}; }
			fi
			;;

			zstd|pzstd)
			# pzstd: suppress the progress bar
			if [ $m = "dc" ]; then
				_cmd(){ ${p} -q${m} ${FILE}.${p}   > /dev/null; }
			else
				_cmd(){ ${p} -q${m} ${FILE}        > ${FILE}.${p}; }
			fi
			;;

			pixz)
			if [ $m = "dc" ]; then
				_cmd(){ ${p} -d          -i ${FILE}.${p} -o /dev/null; }
			else
				qual=$(echo $m | sed 's/c$//')				# Sigh...
				_cmd(){ ${p} -k -${qual} -i ${FILE}      -o ${FILE}.${p}; }
			fi
			;;

			*)
			# All the sane programs out there...
			if [ $m = "dc" ]; then
				_cmd(){ ${p} -${m} ${FILE}.${p} > /dev/null; }
			else
				_cmd(){ ${p} -${m} ${FILE}      > ${FILE}.${p}; }
			fi
			;;
		esac

		# We could move the counter to the outer loop, but then we'd have
		# to play more tricks with our statistics below.
		n=0
		while [ $n -lt $RUNS ]; do
			_cmd
			n=$((n+1))
		done

		# Statistics
		  END=$(date +%s)
		 DIFF=$(echo "scale=2; ($END - $START) / $n" | bc -l)
		if [ $m = "dc" ]; then
			echo "### $p/$m:	$DIFF seconds"
		else
			SIZE2=$(ls -go "$FILE"."$p" | awk '{print $3}')			# More portable than stat(1)
			RATIO=$(echo "scale=3; 100 - ($SIZE2 / $SIZE1 * 100)" | bc -l)
			echo "### $p/$m:	$DIFF seconds / $RATIO% smaller "
		fi

	done			# END PROGRAMS
	echo
done				# END MODES
