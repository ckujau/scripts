#!/bin/sh
#
# (c)2015 Christian Kujau <lists@nerdbynature.de>
#
# Find duplicate files in a directory. That is, files
# with duplicate content.
#
# ----
# Benchmark over 2519 files:
# $ find_dups.sh .
# Duplicate files:
# 38cbf1962697767b098115b85de24fe6  ./f2598273.jpg
# 38cbf1962697767b098115b85de24fe6  ./f2598272.jpg
# 
#            All files: 2519
# Files with same size: 373
#      Duplicate files: 2
#     Time to complete: 1 seconds
# 
# Running again, brute-force mode:
# 38cbf1962697767b098115b85de24fe6  ./f2598272.jpg
# 38cbf1962697767b098115b85de24fe6  ./f2598273.jpg
#
#     Time to complete: 9 seconds (brute force)
# ----
#
# One-line-version, but w/o the statistics:
#
# find "$DIR" -type f -printf "%s\n" | sort -n | uniq -d | \
# 	xargs -I'{}' -n1 find "$DIR" -type f -size '{}'c -print0  | \
#	xargs -0 md5sum | uniq -w32 -D 
#
if [ ! -d "$2" ]; then
	echo "Usage: `basename $0` [smart|brute] [dir]"
	exit 1
else
	DIR="$2"
fi

TEMP=`mktemp`
trap "rm -f $TEMP $TEMP.fallout $TEMP.fallout.md5 $TEMP.fallout.dup; exit" EXIT INT TERM HUP

case $1 in
	smart)
	BEGIN=`date +%s`
	printf "### Gather size & name of all files... "
	find "$DIR" -type f -exec stat -c %s:%n '{}' + > $TEMP
	cat "$TEMP" | wc -l					# No UUOC here, but we don't want the leading spaces from wc(1)
	
	printf "### Gather files of the same size... "
	awk -F: '{print $1}' $TEMP | sort | uniq -d | while read s; do
		grep ^"$s" $TEMP
	done | sort -u > "$TEMP".fallout			# The "sort -u" at the end is crucial :)
	cat "$TEMP".fallout | wc -l

	printf "### Calculate the md5 checksums... "
	awk -F: '{print $2}' "$TEMP".fallout | while read f; do
		md5sum "$f" >> "$TEMP".fallout.md5
	done
	cat "$TEMP".fallout.md5 | wc -l
	
	# Duplicate files, if any
	echo
	echo "Duplicate files:"
	awk '{print $1}' "$TEMP".fallout.md5 2>/dev/null | sort | uniq -d | while read d; do
		grep ^"$d" "$TEMP".fallout.md5
		echo
	done | tee "$TEMP".fallout.dup
	END=`date +%s`

	# Statistics
	echo
	echo "           All files: $(cat "$TEMP"             | wc -l)"
	echo "Files with same size: $(cat "$TEMP".fallout     | wc -l)"
	echo "     Duplicate files: $(expr `egrep -c '^[[:alnum:]]' "$TEMP".fallout.dup` / 2)"
	echo "    Time to complete: $(expr $END - $BEGIN) seconds"
	echo
	;;

	brute)
	BEGIN=`date +%s`
	find "$DIR" -type f -exec md5sum '{}' + > "$TEMP"
	sort -k1 $TEMP | uniq -w32 -D	> "$TEMP".dup		# Print _all_ duplicate lines

	echo
	echo "Duplicate files:" && cat    "$TEMP".dup
	END=`date +%s`
	echo
	echo "           All files: $(cat "$TEMP"             | wc -l)"
	echo "     Duplicate files: $(expr `egrep -c '^[[:alnum:]]' "$TEMP".dup` / 2)"
	echo "    Time to complete: $(expr $END - $BEGIN) seconds"
	;;

	*)
	echo "Usage: `basename $0` [smart|brute] [dir]"
	exit 1
	;;
esac
