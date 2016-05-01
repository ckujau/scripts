#!/bin/sh
#
# (c)2009 Christian Kujau <lists@nerdbynature.de>
# therm_adt746x cannot be queried via i2c, so
# we're not using lm_sensors but this little script
#
renice 10 $$ > /dev/null
BASE=/sys/devices/temperatures

case $1 in
	-s|--short)
	echo "CPU: $(cat $BASE/sensor1_temperature) ($(awk '/^clock/ {print $3}' /proc/cpuinfo \
			| sed 's/\.[0-9]*//')) Fan: $(sed 's/.*(//;s/ rpm)$//' \
			< $BASE/sensor1_fan_speed) GPU: $(cat $BASE/sensor2_temperature)"
	;;

	-b)
	# If pmu_battery is present
	find /sys/ -type f | grep batte | egrep -v 'uevent|srcversion|initstate|refcnt|sections/\.|autosuspend_delay_ms|note.gnu.build' | \
		xargs grep . | sed 's/.*pmu-battery.[0-9]\///;s/:/		/'
	;;

	-h)
	echo "Usage: `basename $0` [-s]  ....print short summary"
	echo "                  [-b]  ....print battery status"
	echo "                  [-h]  ....print this help text"
	echo "With no arguments supplied, we will print out a long summary."
	;;

	*)
	for p in $BASE/sensor1_location \
		 $BASE/sensor1_fan_speed \
		 $BASE/sensor1_temperature \
		 $BASE/sensor1_limit \
		 $BASE/sensor2_location \
		 $BASE/sensor2_temperature \
		 $BASE/sensor2_limit; do
		echo "$(basename $p)	$(cat $p)"
	done
	# As a bonus, print our current clockspeed
	awk '/^clock/ {print $1"			"$3}' /proc/cpuinfo
	;;
esac
