#!/bin/sh
#
# (c)2014 Christian Kujau <lists@nerdbynature.de>
# Tmpfs vs Ramfs vs Ramdisk
#
DIR_TMPFS=/mnt/tmpfs
DIR_RAMFS=/mnt/ramfs
DIR_RAMDISK=/mnt/ramdisk
RESULTS=/var/tmp/bonnie
FS="btrfs ext2 ext3 ext4 jfs reiserfs xfs"		# Adjust as needed

# We need a 2nd argument as well.
if [ -z "$2" ]; then
	echo "Usage: $0 [tmpfs|ramfs|ramdisk] [size(MB)]"
	exit 1
else
	SIZE="$2"
fi

# Create (missing) directories
mkdir -p -m0700 $DIR_TMPFS $DIR_RAMFS $DIR_RAMDISK $RESULTS || exit

# Benchmark cycle
benchmark() {
	B_DIR="$1"
	B_TYPE="$2"
	B_SIZE=$(expr $SIZE / 5)			# -s file size
	 B_RAM=$(expr $SIZE / 10)			# -r RAM size
	B_NUMFILES=$(expr $SIZE / $B_SIZE)		# -n file count
	B_NUMTESTS=1					# -x test count
	bonnie++ -d $B_DIR -s $B_SIZE -n $B_NUMFILES -m $B_TYPE -r $B_RAM -x $B_NUMTESTS -u root \
		1>$RESULTS/bonnie-$B_TYPE.csv 2>$RESULTS/bonnie-$B_TYPE.err
}

# Switch
case $1 in
	tmpfs)
	mount -t tmpfs -o size="$SIZE"M tmpfs $DIR_TMPFS

	benchmark $DIR_TMPFS $1
	umount $DIR_TMPFS
	;;

	ramfs)
	mount -t ramfs -o size="$SIZE"M ramfs $DIR_RAMFS

	benchmark $DIR_RAMFS $1
	umount $DIR_RAMFS
	;;

	ramdisk)
	lsmod | grep -q brd && rmmod brd
	modprobe brd rd_size=$(expr "$SIZE" \* 1024)

	# Which filesystem should we use?
	for fs in $FS; do
		case $fs in
			btrfs)
			M_OPTIONS="-f"
			;;

			ext2|ext3|ext4)
			M_OPTIONS="-q -F"
			;;

			jfs|reiserfs|xfs)
			M_OPTIONS="-qf"
			;;
		esac
		mkfs.$fs $M_OPTIONS /dev/ram0 > /dev/null 2>&1	|| continue
		mount -t $fs /dev/ram0 $DIR_RAMDISK		|| continue
		benchmark $DIR_RAMDISK "$1"_"$fs"
		sleep 1
		umount $DIR_RAMDISK || break
	done
	sleep 1
	rmmod brd
	;;

	*)
	echo "Usage: $0 [tmpfs|ramfs|ramdisk] [size(MB)]"
	exit 1
	;;
esac

