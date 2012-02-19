#!/bin/bash
#
# (C) Mule, 2009-08-07
# http://breakingsystemsforfunandprofit.com/archives/118
#
DIR=/var/www/ternet
while read URL; do
	SURL=$(echo ${URL} | cut -d" " -f1)
	echo ${SURL} | egrep -qi "\.(jp(e)?g|gif|png|tiff|bmp|ico)$" &&
	(
	umask 002
	PIC=$$-${RANDOM}
	wget -q -O ${DIR}/${PIC}.tmp ${SURL}
	convert -quiet ${DIR}/${PIC}.tmp -flop ${DIR}/${PIC}.png
	rm -f ${DIR}/${PIC}.tmp
	echo http://127.0.0.1/ternet/${PIC}.png
	) || echo $URL
done
