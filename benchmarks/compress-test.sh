#!/usr/bin/env ksh
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
# FIXME:
# * brotli understands -q[0..99], so maybe we can employ a simple mapping
#   scheme here? E.g. "gzip -1c" ~ "brotli -q10"? But before we do this,
#   we'll have to read up on its documentation first.
#
# * zstd supports -[1..22] as compression levels. Should we employ a mapping
#   scheme here as well? E.g. "gzip -6c" ~ "zstd -10c"?
#
PATH=/usr/local/bin:/usr/bin:/bin
PROGRAMS=${PROGRAMS:-gzip pigz bzip2 pbzip2 xz pxz lzma plzma brotli zstd pzstd}
MODES=${MODES:-9c 1c dc}			# {1..9}c for most programs
						# dc for decompression
# unset me!
# DEBUG=echo

_help() {
	echo "Usage: `basename $0` [-n runs] [-f file]"
	echo "       `basename $0` [-r results]"
	echo
	echo "Available environment variables that can be set:"
	echo "PROGRAMS (default: $PROGRAMS)"
	echo "   MODES (default: $MODES)"
	echo
	exit 1
}

_report() {
	echo "### Fastest compressor:"
	grep -v /dc "$REPORT" | sort -nk3
	echo

	echo "### Smallest size:"
	grep -v /dc "$REPORT" | sort -nrk6
	echo

	echo "### Fastest decompressor:"
	grep    /dc "$REPORT" | sort -nk3
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
[ -f "$REPORT" ] && _report

# Default to one run
RUNS=${runs:-1}

# Read file into RAM once
[ -f "$FILE" ] && cat "$FILE" > /dev/null || _help

# Iterate through all programs, modes
for o in $MODES; do
	for p in $PROGRAMS; do
		SIZE1=`ls -go "$FILE" | awk '{print $3}'`
		START=`date +%s`

		# brotli: why can't you have the same options, hm?
		if [ $p = "brotli" ]; then
			if [ $o = "dc" ]; then
				or=$o					# Save the original MODE
				oe="-decompress --input"		# Mind the missing "-"
			else
				# Sigh...
				Q=$(echo $o | sed 's/c$//')
				or=$o					# Save the original MODE
				oe="-force --quality $Q --input"	# Mind the missing "-"
			fi
		else
			or=$o						# Save the original MODE
			oe=$o						# Set effective MODE to $o
		fi

		# pzstd: suppress the progress bar
		if [ $p = "zstd" ] || [ $p = "pzstd" ]; then
			oe=q${o}
		fi

		# Repeat n times
		for n in {1..$RUNS}; do
		#	echo "### RUN: $n MODE: $o  PROG: $p"
			# Discard output during decompression
			if [[ $o == "dc" ]] || [[ $oe == "qdc" ]] || [[ $oe =~ "decompress" ]]; then
				$DEBUG ${p} -${oe} "$FILE"."$p" > /dev/null
			else							# Compress
				$DEBUG ${p} -${oe} "$FILE" > "$FILE"."$p"
			fi
		done		# END RUNS

		# Statistics
		  END=`date +%s`
		SIZE2=`ls -go "$FILE"."$p" | awk '{print $3}'`
		 DIFF=`echo "scale=2; ($END - $START) / $n" | bc -l`
		if [[ $o == "dc" ]] || [[ $oe == "qdc" ]] || [[ $oe =~ "decompress" ]]; then
			echo "### $p/$or:	$DIFF seconds"
		else
			RATIO=`echo "scale=3; 100 - ($SIZE2 / $SIZE1 * 100)" | bc -l`
			echo "### $p/$or:	$DIFF seconds / $RATIO% smaller "
		fi

	# Reset effective MODE
	unset oe
	done			# END PROGRAMS
done				# END MODES
