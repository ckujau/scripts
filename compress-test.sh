#!/bin/sh

if [ ! -f "$1" ]; then
	echo "Usage: `basename $0` [file]"
	exit 1
else
	FILE="$1"
fi

# unset me!
# DEBUG=echo

cat "$FILE" > /dev/null		# Utilize caching...

for o in 9c 1c dc; do
	for p in gzip bzip2 pbzip2 xz lzma; do
		SIZE1=`stat -c %s "$FILE"`
		START=`date +%s`

		# special case for decompression
		if [ $o = "dc" ]; then
			$DEBUG "$p" -"$o" "$FILE"."$p" > /dev/null
		else
			$DEBUG "$p" -"$o" "$FILE" > "$FILE"."$p"
		fi
		  END=`date +%s`
		SIZE2=`stat -c %s "$FILE"."$p"`
		 DIFF=`echo "scale=2; $END - $START" | bc -l`
		if [ $o = "dc" ]; then
			echo "### $p/$o:	$DIFF seconds"
		else
			RATIO=`echo "scale=3; 100 - ($SIZE2 / $SIZE1 * 100)" | bc -l`
			echo "### $p/$o:	$DIFF seconds / $RATIO% smaller "
		fi
	done
done
