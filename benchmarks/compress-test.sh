#!/bin/bash
#
# (c)2011 Christian Kujau <lists@nerdbynature.de>
#
# Compress a file with different programs and see how long it took to do this.
# Note: we need Bash for string-matching here.
#
# Compare the results like this:
#
# for i in {1..3}; do ../compress-test.sh test.file | tee results_${i}.out; done
#
# for o in 9c 1c dc; do
#   for p in gzip pigz bzip2 pbzip2 xz lzma zstd brotli; do
#     awk "/"$p"\/"$o"/ {sum+=\$3} END {print \"$p/$o\t\", sum/8}" results_*.out
#   done | sort -nk2; echo
# done
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
# FIXME:
# * brotli understands -q[0..99], so maybe we can employ a simple mapping
#   scheme here? E.g. "gzip -1c" ~ "brotli -q10"? But before we do this,
#   we'll have to read up on its documentation first.
#
# * zstd supports -[1..22] as compression levels. Should we employ a mapping
#   scheme here as well? E.g. "gzip -6c" ~ "zstd -10c"?
#
PROGRAMS="gzip zstd brotli"
PROGRAMS="gzip pigz bzip2 pbzip2 xz lzma brotli zstd pzstd"
MODES="9c 1c dc"				# {1..9}c for most programs
						# dc for decompression
# unset me!
# DEBUG=echo

if [ ! -f "$1" ]; then
	echo "Usage: `basename $0` [file]"
	exit 1
else
	FILE="$1"
fi

cat "$FILE" > /dev/null			# Read file into RAM

# Iterate through all programs, modes
for o in $MODES; do
	for p in $PROGRAMS; do
#	echo "### MODE: $o  PROG: $p"
		SIZE1=`stat -c %s "$FILE"`
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
	
		# discard output on decompression
		if [[ $o == "dc" ]] || [[ $oe == "qdc" ]] || [[ $oe =~ "decompress" ]]; then
			$DEBUG ${p} -${oe} "$FILE"."$p" > /dev/null
		else
			$DEBUG ${p} -${oe} "$FILE" > "$FILE"."$p"
		fi

		# Statistics
		  END=`date +%s`
		SIZE2=`stat -c %s "$FILE"."$p"`
		 DIFF=`echo "scale=2; $END - $START" | bc -l`
		if [[ $o == "dc" ]] || [[ $oe == "qdc" ]] || [[ $oe =~ "decompress" ]]; then
			echo "### $p/$or:	$DIFF seconds"
		else
			RATIO=`echo "scale=3; 100 - ($SIZE2 / $SIZE1 * 100)" | bc -l`
			echo "### $p/$or:	$DIFF seconds / $RATIO% smaller "
		fi

	# Reset effective MODE
	unset oe
	done
done
