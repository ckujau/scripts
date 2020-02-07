#!/bin/sh
#
# (c)2014 Christian Kujau <lists@nerdbynature.de>
#
# Convert music from/to various formats
#
# TODO: Add more conversions, much more :-)
#
# > Convert flac to (almost) anything
# > https://forums.gentoo.org/viewtopic-t-554188.html
#
# > .ogg to .mp3
# > https://forums.gentoo.org/viewtopic-t-463068.html
#
if [ ! $# -eq 2 ] || [ ! -f "$2" ]; then
	echo "Usage: $(basename "$0") [conversion] [file]"
	echo "Conversions: flac2mp3, m4a2mp3, ogg2mp3"
	exit 1
else
	CONVERSION="$1"
	FILE="$2"
	PATH=$PATH:/opt/lame/bin
fi

# LAME defaults
# -m j			- joint stereo (default)
# -q 0			- quality (0 best, 9 fastest, default: 5)
# --vbr-new		- invokes newest VBR algorithm
# -V 0			- enable VBR (0 best, 9 fastest, default: 4)
# -s 44.1		- sample rate
# --add-id3v2		- force addition of version 2 tag
# --ignore-tag-errors	- ignore errors in values passed for tags
# --pad-id3v2		- ?
LAMEARGS="-m j -q 5 --vbr-new -V 4 -s 44.1 --add-id3v2 --ignore-tag-errors"

case $CONVERSION in
	flac2mp3)
	# Convert FLAC to MP3
	# https://wiki.archlinux.org/index.php/Convert_FLAC_to_MP3
	# Software needed: flac, lame
	OUTPUT=${FILE%.flac}.mp3
	 TRACK=$(metaflac --show-tag=TRACKNUMBER "$FILE" | sed s/.*=//)
	 TITLE=$(metaflac --show-tag=TITLE  "$FILE" | sed s/.*=//)
	ARTIST=$(metaflac --show-tag=ARTIST "$FILE" | sed s/.*=//)
	 ALBUM=$(metaflac --show-tag=ALBUM  "$FILE" | sed s/.*=//)
	  DATE=$(metaflac --show-tag=DATE   "$FILE" | sed s/.*=//)
	 GENRE=$(metaflac --show-tag=GENRE  "$FILE" | sed s/.*=//)
	#
	# lame options:
	# -m j		joint stereo
	# -q 0		slowest & best possible version of all algorithms
	# --vbr-new	newest VBR algorithm
	# -V 0		highest quality
	# -s 44.1	sampling frequency
	#
	# Note: if GENRE is empty, use "12" (other). If TRACKNUMBER is empty, use "0".
	flac --stdout --decode "$FILE" | \
	lame -m j -q 0 --vbr-new -V 0 -s 44.1 --add-id3v2 --pad-id3v2 \
		--ignore-tag-errors --tn "${TRACK:-0}" --tt "$TITLE" \
		--ta "$ARTIST" --tl "$ALBUM" --ty "$DATE" --tg "${GENRE:-12}" - "$OUTPUT"
	;;

	m4a2mp3)
	# Software needed: faad, lame
	OUTPUT=${FILE%.m4a}.mp3
	 TRACK=$(faad --info "$FILE" 2>&1 | grep ^track  | sed 's/^.*: //')
	 TITLE=$(faad --info "$FILE" 2>&1 | grep ^title  | sed 's/^.*: //')
	ARTIST=$(faad --info "$FILE" 2>&1 | grep ^artist | sed 's/^.*: //')
	 ALBUM=$(faad --info "$FILE" 2>&1 | grep ^album  | sed 's/^.*: //')
	  DATE=$(faad --info "$FILE" 2>&1 | grep ^date   | sed 's/^.*: //')
	 GENRE=$(faad --info "$FILE" 2>&1 | grep ^genre  | sed 's/^.*: //')

	faad --stdio "$FILE" | lame "$LAMEARGS" --tn "${TRACK:-0}" --tt "$TITLE" \
		--ta "$ARTIST" --tl "$ALBUM" --ty "$DATE" --tg "${GENRE:-12}" - "$OUTPUT"
	;;

	ogg2mp3)
	OUTPUT=${FILE%.ogg}.mp3
	eval $(ogginfo -qv "$FILE" | awk '/ARTIST/ || /TITLE/' | sed 's/^     //')
#	echo "ARTIST: $ARTIST TITLE: $TITLE"
	if [ -z "$ARTIST" ] || [ -z "$TITLE" ]; then
		echo "WARNING: Not enough metadata, trying to gather track information from filename! ($FILE)"
		 TRACK=$(ls "$FILE" | awk -F\  '{print $1}')
		 TITLE=$(ls "$FILE" | sed 's/^[0-9]* - //;s/\.ogg//')

		# Try to find the ARLBUM via the directory name
		cd "$(dirname "$FILE")" || exit
		ALBUM="$(basename $(pwd))"
		echo "TRACK: $TRACK TITLE: $TITLE ALBUM: $ALBUM"
	fi
	oggdec --quiet "$FILE" --output - | lame "$LAMEARGS" --tn "${TRACK:-0}" --tt "$TITLE" \
		--tl "$ALBUM" - "$OUTPUT"
	;;

	*)
	echo "$(basename "$0"): conversion $CONVERSION unknow."
	exit 1
	;;
esac
