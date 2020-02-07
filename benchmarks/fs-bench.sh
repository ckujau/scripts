#!/bin/sh
#
# (c)2009 Christian Kujau <lists@nerdbynature.de>
#
# Yet another filesystem benchmark script
#
# - bonnie++
# - dbench
# - iozone3
# - tiobench
# - generic operations, like tar/touch/rm
#
# TODO:
# - different mount options for each filesystems
# - different benchmark options
# - integrate fio? (https://github.com/axboe/fio)
#
# v0.1 - initial version
# v0.2 - disabled 2 filesystems
#        ufs - https://bugs.debian.org/526586 ("mkfs.ufs: could not find special device")
#        nilfs2 - filesystem fills up until ENOSPC
# v0.3 - run tiobench with only 1 thread, otherwise we get:
#        Illegal division by zero at /usr/bin/tiobench line 163
# v0.4 - rewrite for ksh
# v0.5 - replace "date +%s"
#        enable NILFS2, UFS and ZFS again
#        rework the generic tests
#
# Prerequisites:
# apt-get install bc bonnie++ dbench pciutils hdparm e2fsprogs btrfs-tools \
#		jfsutils reiserfsprogs reiser4progs xfsprogs tiobench ksh
# 
CONF="/usr/local/etc/fs-bench.conf"

log() {
echo "$(date +'%F %H:%M:%S'): $1"
[ -n "$2" ] && exit "$2"
}

# little helper function to warn if we might run out of diskspace during the benchmark.
# Takes three arguments (count in 1024, size in bytes and a multiplier) seperated by a colon,
# result will be given in KB:
#    $ echo "1:1024:2" | chkfree
#   -> 2048
chkfree() {
eval $(awk -F: '{p=sprintf ("%.0f", ($1 * $2 * $3)); print "ESTIM="p }')
eval $(df -k "$MPT" | awk '!/Filesystem/ {print "AVAIL="$4}')
if [ "$ESTIM" -ge "$AVAIL" ]; then
	log "WARNING: $ESTIM KB estimated but only $AVAIL KB available - $b could fail!"
else
	log "DEBUG:  $ESTIM KB estimated, $AVAIL KB available" >> "$LOG"/raw/bonnie-"$fs".log
fi
}

# sanity checks
if [ ! -b "$1" ] || [ ! -d "$2" ] || [ ! -f $CONF ]; then
	log "Usage: $(basename "$0") [dev] [mpt]"
	log "Make sure $CONF exists!" 1
else
	DEV="$1"
	MPT="$(echo "$2" | sed 's/\/$//')"
	. "$CONF"
fi

# overwrite results dir?
if [ -d "$LOG" ]; then
	printf "Directory $LOG already exists, overwrite? (y/n) " && read c
	if [ "$c" = "y" ]; then
		$DEBUG rm -rf "$LOG"
	else
		log "Aborted." 1
	fi
fi
$DEBUG mkdir -p   "$LOG"/raw "$LOG"/env
$DEBUG cp "$0"    "$LOG"/env/$(basename "$0").txt
$DEBUG cp "$CONF" "$LOG"/env/$(basename $CONF).txt
$DEBUG gzip -dc /proc/config.gz  > "$LOG"/env/config.txt 2>/dev/null
$DEBUG cp /boot/config-$(uname -r) "$LOG"/env/config-$(uname -r).txt 2>/dev/null
$DEBUG dmesg > "$LOG"/env/dmesg.txt
$DEBUG lspci > "$LOG"/env/lspci.txt
$DEBUG hdparm -tT "$DEV" > "$LOG"/env/hdparm.txt

########################################################
# MKFS
########################################################
mkfs_btrfs() {
  log "mkfs.btrfs $DEV" >> "$LOG"/raw/commands.txt
$DEBUG mkfs.btrfs "$DEV" 1>/dev/null
  log "mount -t btrfs -o noatime $DEV $MPT" >> "$LOG"/raw/commands.txt
$DEBUG mount -t btrfs -o noatime "$DEV" "$MPT"
ERR=$?
}

mkfs_ext2() {
  log "mkfs.ext2 -Fq $DEV" >> "$LOG"/raw/commands.txt
$DEBUG mkfs.ext2 -Fq "$DEV"
  log "mount -t ext2 -o noatime,user_xattr $DEV $MPT" >> "$LOG"/raw/commands.txt
$DEBUG mount -t ext2 -o noatime,user_xattr "$DEV" "$MPT"
ERR=$?
}

mkfs_ext3() {
  log "mkfs.ext3 -Fq $DEV" >> "$LOG"/raw/commands.txt
$DEBUG mkfs.ext3 -Fq "$DEV"
  log "mount -t ext3 -o noatime,user_xattr $DEV $MPT" >> "$LOG"/raw/commands.txt
$DEBUG mount -t ext3 -o noatime,user_xattr "$DEV" "$MPT"
ERR=$?
}

mkfs_ext4() {
  log "mkfs.ext4 -Fq $DEV" >> "$LOG"/raw/commands.txt
$DEBUG mkfs.ext4 -Fq "$DEV"
  log "mount -t ext4 -o noatime,user_xattr $DEV $MPT" >> "$LOG"/raw/commands.txt
$DEBUG mount -t ext4 -o noatime,user_xattr "$DEV" "$MPT"
ERR=$?
}

mkfs_jfs() {
  log "mkfs.jfs -q $DEV" >> "$LOG"/raw/commands.txt
$DEBUG mkfs.jfs -q "$DEV" 1>/dev/null
  log "mount -t jfs -o noatime $DEV $MPT" >> "$LOG"/raw/commands.txt
$DEBUG mount -t jfs -o noatime "$DEV" "$MPT"
ERR=$?
}

mkfs_nilfs2() {
  log "mkfs.nilfs2 -q $DEV" >> "$LOG"/raw/commands.txt
$DEBUG mkfs.nilfs2 -q "$DEV"
  log "mount -t nilfs2 -o noatime $DEV $MPT" >> "$LOG"/raw/commands.txt
$DEBUG mount -t nilfs2 -o noatime "$DEV" "$MPT" 2>/dev/null
ERR=$?
}

mkfs_reiserfs() {
  log "mkfs.reiserfs -qf $DEV" >> "$LOG"/raw/commands.txt
$DEBUG mkfs.reiserfs -qf "$DEV" > /dev/null 2>&1
  log "mount -t reiserfs -o noatime,user_xattr $DEV $MPT" >> "$LOG"/raw/commands.txt
$DEBUG mount -t reiserfs -o noatime,user_xattr "$DEV" "$MPT"
ERR=$?
}

mkfs_reiser4() {
  log "mkfs.reiser4 -yf $DEV" >> "$LOG"/raw/commands.txt
$DEBUG mkfs.reiser4 -yf "$DEV"
  log "mount -t reiser4 -o noatime $DEV $MPT" >> "$LOG"/raw/commands.txt
$DEBUG mount -t reiser4 -o noatime "$DEV" "$MPT"
ERR=$?
}

mkfs_ufs() {
  log "mkfs.ufs -J -O2 -U $DEV" >> "$LOG"/raw/commands.txt
$DEBUG mkfs.ufs -J -O2 -U "$DEV" > /dev/null
  log "mount -t ufs -o ufstype=ufs2,noatime $DEV $MPT" >> "$LOG"/raw/commands.txt
$DEBUG mount -t ufs -o ufstype=ufs2,noatime "$DEV" "$MPT"
ERR=$?
}

mkfs_xfs() {
  log "mkfs.xfs -qf $DEV" >> "$LOG"/raw/commands.txt
$DEBUG mkfs.xfs -qf "$DEV"
  log "mount -t xfs -o noatime $DEV $MPT" >> "$LOG"/raw/commands.txt
$DEBUG mount -t xfs -o noatime "$DEV" "$MPT"
ERR=$?
}

mkfs_zfs() {
# special case different operating systems
case $(uname -s) in
	Linux)
	if [ -z "$(pgrep zfs-fuse)" ]; then
		log "zfs-fuse not running!"
		false
	fi
	;;

	SunOS)
	if [ ! -x "$(which zpool)" ]; then
		log "zfs not found!"
		false
	fi
	;;
esac
  log "zpool create -f -O atime=off -m $MPT ztest $DEV" >> "$LOG"/raw/commands.txt
$DEBUG zpool create -f -O atime=off -m "$MPT" ztest "$DEV"
ERR=$?
}

umountfs() {
case $fs in
	zfs)
	# ...and special case Linux/ZFS again
	if [ "$(uname -s)" = Linux ] && [ -z "$(pgrep zfs-fuse)" ]; then
		log "zfs-fuse not running!" 1
	fi
	$DEBUG sync
	$DEBUG sleep 5
	  log "zpool destroy -f ztest" >> "$LOG"/raw/commands.txt
	$DEBUG zpool destroy -f ztest >> "$LOG"/raw/zfs.log 2>&1
	# sometimes, this just fails (why?)
	if [ ! $? = 0 ]; then
		log "Destroying ZFS pool failed, will try again in 5 seconds!" >> "$LOG"/raw/zfs.log
		$DEBUG sync
		$DEBUG sleep 5
		  log "zpool destroy -f ztest" >> "$LOG"/raw/commands.txt
		$DEBUG zpool destroy -f ztest || log "Unmounting $fs failed!" 1
	fi
	;;

	*)
	  log "umount $MPT" >> "$LOG"/raw/commands.txt
	$DEBUG umount "$MPT" || log "Unmounting $fs failed!" 1
	;;
esac
}

########################################################
# BENCHMARKS
########################################################

run_bonnie() {
eval conf_bonnie
log "Running $b on $fs..."
echo "$NUMFILES" | awk -F: '{printf $1 ":" $2 ":1.1"}' | chkfree
  log "bonnie++ -d $MPT -s $SIZE -n $NUMFILES -m $fs -r $RAM -x $NUMTESTS -u root" >> "$LOG"/raw/commands.txt
$DEBUG bonnie++ -d "$MPT" -s "$SIZE" -n "$NUMFILES" -m "$fs" -r "$RAM" -x "$NUMTESTS" -u root 1>"$LOG"/raw/bonnie-"$fs".csv 2>"$LOG"/raw/bonnie-"$fs".err
$DEBUG egrep -hv '^format' "$LOG"/raw/bonnie-*.csv | bon_csv2html > "$LOG"/bonnie.html
}

########################################################
run_stress() {
#
# Based on https://oss.oracle.com/~mason/stress.sh
#      Copyright (C) 1999 Bibliotech Ltd., 631-633 Fulham Rd., London SW6 5UQ.
#      $Id: stress.sh,v 1.2 1999/02/10 10:58:04 rich Exp $
#
eval conf_stress
log "Running $b on $fs (size: $(du -sk "$CONTENT" | awk '{print $1 / 1024 " MB"}'))..."
$DEBUG mkdir "$MPT"/stress || log "cannot create $MPT/stress" 1
$DEBUG    cd "$MPT"/stress || log "cannot cd into $MPT/stress" 1

# computing MD5 sums over content directory
find "$CONTENT" -type f -exec md5sum '{}' + | sort > "$MPT"/content.sums

# !!FIXME!!
# starting stress test processes
p=1
while [ $p -le "$CONCURRENT" ]; do
	(
	# wait for all processes to start up.
	if [ "$STAGGER" = "yes" ]; then
		$DEBUG sleep $(expr 2 \* $p)
	else
		$DEBUG sleep 1
	fi

	r=1
	while [ $r -le "$RUNS" ]; do
		log "Running stresstest in $MPT/stress/$p (r: $r)..."
		# Remove old directories.
		$DEBUG rm -rf "$MPT"/stress/$p

		# copy content
		$DEBUG mkdir "$MPT"/stress/$p || log "cannot create $MPT/stress/$p"
		$DEBUG cp -dRx "$CONTENT"/* "$MPT"/stress/$p || log "cannot copy $CONTENT to $MPT/stress/$p"

		# compare the content and the copy.
		$DEBUG cd "$MPT"/stress/$p
		$DEBUG find . -type f -exec md5sum '{}' + | sort > "$MPT"/stress.$p
		$DEBUG diff -q "$MPT"/content.sums "$MPT"/stress.$p
		if [ $? != 0 ]; then
			log "corruption found in $MPT/stress/$p (r: $r)"
			continue
		fi
		$DEBUG cd "$MPT"/stress
		$DEBUG rm -f "$MPT"/stress.$p
	r=$(expr $r + 1)
	done
	) &
p=$(expr $p + 1)
done
}

########################################################
run_dbench() {
eval conf_dbench
  log "Running $b on $fs..."
  log "dbench -x -t $TIME -D $MPT $NPROC" >> "$LOG"/raw/commands.txt
$DEBUG dbench -x -t "$TIME" -D "$MPT" "$NPROC" > "$LOG"/raw/dbench-"$fs".log
echo "$fs:	$(egrep '^Throughput' "$LOG"/raw/dbench-"$fs".log)" >> "$LOG"/dbench.txt
}

run_iozone() {
eval conf_iozone
  log "Running $b on $fs..."
$DEBUG cd "$MPT" || log "cannot cd into $MPT" 1
  log "iozone -a -c -S $CACHESIZE -s $FILESIZE" >> "$LOG"/raw/commands.txt
$DEBUG iozone -a -c -S "$CACHESIZE" -s "$FILESIZE" > "$LOG"/raw/iozone-"$fs".log
}

run_tiobench() {
eval conf_tiobench
log "Running $b on $fs..."
  log "tiobench --identifier fs_"$fs" --size $SIZE --numruns $NUMRUNS --dir $MPT --block 4096 --block 8192 --threads 1" >> "$LOG"/raw/commands.txt
$DEBUG tiobench --identifier fs_"$fs" --size "$SIZE" --numruns "$NUMRUNS" --dir "$MPT" --block 4096 --block 8192 --threads 1 1>"$LOG"/raw/tiobench-"$fs".log 2>"$LOG"/raw/tiobench-"$fs".err

# results are hard to summarize
echo "                               File  Blk   Num                   Avg      Maximum      Lat%     Lat%    CPU" >  "$LOG"/tiobench.txt
echo "                               Size  Size  Thr   Rate  (CPU%)  Latency    Latency      >2s      >10s    Eff" >> "$LOG"/tiobench.txt
for t in "Sequential Reads" "Sequential Writes" "Random Reads" "Random Writes"; do
	echo "$t"
	# adjust -An for more/less than 2 different blocksizes!
	grep -h -A5 "$t" "$LOG"/raw/tiobench-*.log | egrep '^fs_'
	echo
done >> "$LOG"/tiobench.txt
}

run_generic() {
eval conf_generic
SIZE=$(du -sk "$CONTENT" | awk '{print $1 / 1024}')
FSP=$(echo "$fs" | awk '{printf "%9s", $1"\n"}')		# string padding, reiserfs being the longest one
ERR=""
log "Running $b on $fs..."
# - copy content to fs
# - tar up local content
# - copy content within same fs
# - create NUMFILES in NUMDIRS

# tar to
GEN_BEGIN=$(date +%s)
  log "mkdir "$MPT"/tar >> "$LOG"/raw/commands.txt
$DEBUG mkdir "$MPT"/tar
  log "cd "$CONTENT" >> "$LOG"/raw/commands.txt
$DEBUG cd "$CONTENT"
  log "tar -cf - . | tar -C "$MPT"/tar -xf -" >> "$LOG"/raw/commands.txt
$DEBUG tar -cf - . 2>>"$LOG"/raw/generic-"$fs".err | tar -C "$MPT"/tar -xf - 2>>"$LOG"/raw/generic-"$fs".err
  log "diff -r "$CONTENT" "$MPT"/tar" >> "$LOG"/raw/commands.txt
DIFF="$(diff -r "$CONTENT" "$MPT"/tar 2>&1 | grep -v 'No such file or directory')"
[ -z "$DIFF" ] || ERR="- FAILED"
$DEBUG sync
$DEBUG cd /tmp
GEN_END=$(date +%s)
GEN_DUR=$(echo "scale=2; $GEN_END - $GEN_BEGIN" | bc -l)
  SPEED=$(echo "scale=2; $SIZE / $GEN_DUR" | bc -l 2>/dev/null)
log "$FSP.0: $GEN_DUR seconds ($SPEED MB/s) to copy $CONTENT to $MPT and running diff $ERR"  > "$LOG"/raw/generic-"$fs".log
ERR=""

# tar from
GEN_BEGIN=$(date +%s)
  log "cd "$MPT"/tar" >> "$LOG"/raw/commands.txt
$DEBUG cd "$MPT"/tar
  log "tar -cf - . | dd of=/dev/null" >> "$LOG"/raw/commands.txt
$DEBUG tar -cf - . 2>>"$LOG"/raw/generic-"$fs".err | dd of=/dev/null 2>>"$LOG"/raw/generic-"$fs".err
[ $? = 0 ] || ERR="- FAILED"
$DEBUG sync
$DEBUG cd /tmp
GEN_END=$(date +%s)
GEN_DUR=$(echo "scale=2; $GEN_END - $GEN_BEGIN" | bc -l)
  SPEED=$(echo "scale=2; $SIZE / $GEN_DUR" | bc -l 2>/dev/null)
log "$FSP.1: $GEN_DUR seconds ($SPEED MB/s) to tar up content on $MPT $ERR" >> "$LOG"/raw/generic-"$fs".log
ERR=""

# copy
GEN_BEGIN=$(date +%s)
  log "mkdir "$MPT"/copy" >> "$LOG"/raw/commands.txt
$DEBUG mkdir "$MPT"/copy
  log "cp -xfpR "$CONTENT" "$MPT"/copy" >> "$LOG"/raw/commands.txt
$DEBUG cp -xfpR "$CONTENT" "$MPT"/copy 2>>"$LOG"/raw/generic-"$fs".err
[ $? = 0 ] || ERR="- FAILED"
$DEBUG sync
GEN_END=$(date +%s)
GEN_DUR=$(echo "scale=2; $GEN_END - $GEN_BEGIN" | bc -l)
  SPEED=$(echo "scale=2; $SIZE / $GEN_DUR" | bc -l 2>/dev/null)
log "$FSP.2: $GEN_DUR seconds ($SPEED MB/s) to copy $CONTENT on $MPT $ERR" >> "$LOG"/raw/generic-"$fs".log
ERR=""

# cleanup before starting the next test
SIZE_M=$(du -sk "$MPT" | awk '{print $1 / 1024}')
GEN_BEGIN=$(date +%s)
$DEBUG echo "DEBUG-1: $(df -i "$MPT" | grep -v Filesystem)" >> "$LOG"/raw/generic-"$fs".err

  log "rm -rf "$MPT"/tar "$MPT"/copy" >> "$LOG"/raw/commands.txt
$DEBUG rm -rf "$MPT"/tar "$MPT"/copy 2>>"$LOG"/raw/generic-"$fs".err
[ $? = 0 ] || ERR="- FAILED"

$DEBUG echo "DEBUG-2: $(df -i "$MPT" | grep -v Filesystem)" >> "$LOG"/raw/generic-"$fs".err
GEN_END=$(date +%s)
GEN_DUR=$(echo "scale=2; $GEN_END - $GEN_BEGIN" | bc -l)
  SPEED=$(echo "scale=2; $SIZE_M / $GEN_DUR" | bc -l 2>/dev/null)
log "$FSP.3: $GEN_DUR seconds ($SPEED MB/s) to remove content from $MPT $ERR" >> "$LOG"/raw/generic-"$fs".log
ERR=""

# create many files
GEN_BEGIN=$(date +%s)
$DEBUG mkdir "$MPT"/manyfiles
log "for d in seq 1 $NUMDIRS; do mkdir -p $MPT/manyfiles/dir.d && cd $MPT/manyfiles/dir.d && seq 1 $NUMFILES | xargs touch; done" >> "$LOG"/raw/commands.txt
for d in $(seq 1 "$NUMDIRS"); do
	$DEBUG mkdir -p "$MPT"/manyfiles/dir."$d" 2>>"$LOG"/raw/generic-"$fs".err
	$DEBUG cd "$MPT"/manyfiles/dir."$d"       2>>"$LOG"/raw/generic-"$fs".err
	seq 1 "$NUMFILES" | xargs touch           2>>"$LOG"/raw/generic-"$fs".err
done
sync
GEN_END=$(date +%s)
GEN_DUR=$(echo "scale=2; $GEN_END - $GEN_BEGIN" | bc -l)
 NUMDIRS_C=$(find "$MPT"/manyfiles -type d | wc -l)
NUMFILES_C=$(find "$MPT"/manyfiles -type f | wc -l)
[ $(expr "$NUMDIRS_C" - 1) = "$NUMDIRS" ] && [ "$NUMFILES_C" = $(expr "$NUMDIRS" \* "$NUMFILES") ] || ERR="- FAILED"
log "$FSP.4: $GEN_DUR seconds to create $NUMFILES files in each of the $NUMDIRS directories $ERR" >> "$LOG"/raw/generic-"$fs".log
ERR=""

# cleanup before starting the next test
GEN_BEGIN=$(date +%s)
$DEBUG echo "DEBUG-3: $(df -i "$MPT" | grep -v Filesystem)" >> "$LOG"/raw/generic-"$fs".err
  log "rm -rf "$MPT"/manyfiles" >> "$LOG"/raw/commands.txt
$DEBUG rm -rf "$MPT"/manyfiles 2>>"$LOG"/raw/generic-"$fs".err
[ $? = 0 ] || ERR="- FAILED"

$DEBUG echo "DEBUG-4: $(df -i "$MPT" | grep -v Filesystem)" >> "$LOG"/raw/generic-"$fs".err
GEN_END=$(date +%s)
GEN_DUR=$(echo "scale=2; $GEN_END - $GEN_BEGIN" | bc -l)
 INODES=$(echo "$NUMFILES * $NUMDIRS" | bc)
  SPEED=$(echo "scale=2; $INODES / $GEN_DUR" | bc -l 2>/dev/null)
log "$FSP.5: $GEN_DUR seconds ($SPEED i/s) to remove $INODES inodes $ERR" >> "$LOG"/raw/generic-"$fs".log
ERR=""

# create many dirs (we just replace NUMDIRS with NUMFILES and vice versa)
GEN_BEGIN=$(date +%s)
$DEBUG mkdir -p "$MPT"/manydirs
log "for d in seq 1 $NUMFILES; do mkdir -p $MPT/manydirs/dir.d && cd $MPT/manydirs/dir.d && seq 1 $NUMDIRS | xargs touch; done" >> "$LOG"/raw/commands.txt
for d in $(seq 1 "$NUMFILES"); do
	$DEBUG mkdir -p "$MPT"/manydirs/dir."$d" 2>>"$LOG"/raw/generic-"$fs".err
	$DEBUG cd "$MPT"/manydirs/dir."$d"       2>>"$LOG"/raw/generic-"$fs".err
	seq 1 "$NUMDIRS" | xargs touch           2>>"$LOG"/raw/generic-"$fs".err
done
sync
GEN_END=$(date +%s)
GEN_DUR=$(echo "scale=2; $GEN_END - $GEN_BEGIN" | bc -l)
 NUMDIRS_C=$(find "$MPT"/manydirs -type d | wc -l)
NUMFILES_C=$(find "$MPT"/manydirs -type f | wc -l)
[ $(expr "$NUMDIRS_C" - 1) = "$NUMFILES" ] && [ "$NUMFILES_C" = $(expr "$NUMDIRS" \* "$NUMFILES") ] || ERR="- FAILED"
log "$FSP.6: $GEN_DUR seconds to create $NUMDIRS files in each of the $NUMFILES directories $ERR" >> "$LOG"/raw/generic-"$fs".log
ERR=""

# cleanup 
GEN_BEGIN=$(date +%s)
$DEBUG echo "DEBUG-5: $(df -i "$MPT" | grep -v Filesystem)" >> "$LOG"/raw/generic-"$fs".err
  log "rm -rf "$MPT"/manydirs" >> "$LOG"/raw/commands.txt
$DEBUG rm -rf "$MPT"/manydirs 2>>"$LOG"/raw/generic-"$fs".err
[ $? = 0 ] || ERR="- FAILED"

$DEBUG echo "DEBUG-6: $(df -i "$MPT" | grep -v Filesystem)" >> "$LOG"/raw/generic-"$fs".err
GEN_END=$(date +%s)
GEN_DUR=$(echo "scale=2; $GEN_END - $GEN_BEGIN" | bc -l)
 INODES=$(echo "$NUMFILES * $NUMDIRS" | bc)
  SPEED=$(echo "scale=2; $INODES / $GEN_DUR" | bc -l 2>/dev/null)
log "$FSP.7: $GEN_DUR seconds ($SPEED i/s) to remove $INODES inodes $ERR" >> "$LOG"/raw/generic-"$fs".log
ERR=""

# results across all tests, appended after each test
egrep -h seconds "$LOG"/raw/generic-"$fs".log | sed 's/.*[0-9][0-9]://;s/\.[0-9]//' >> "$LOG"/raw/generic_all.txt
# sorted results, generated new after each run
for t in $(seq 0 7); do
	fgrep -h ".$t:" "$LOG"/raw/generic-*.log | sort -n -k4
	echo
done | sed 's/.*:[0-9][0-9]://;s/\.[0-9]//' > "$LOG"/generic.txt
}

########################################################
# MAIN
########################################################
mount | grep -q "$MPT" && log "$MPT is already mounted!" 1

BEGIN=$(date +%s)
# iterating through filesystems
for fs in $FILESYSTEMS; do
	echo "========================================================"
	FS_BEG=$(date +%s)

	# mkfs, mount, umount for every benchmark
	for b in $BENCHMARKS; do

		# See, if we're to skip this one
		echo "$SKIP" | grep -q "$fs.$b"
		if [ $? = 0 ]; then
			log "Skipping $b on $fs!"
			continue
		fi
		mkfs_"$fs"
		if [ ! $ERR = 0 ]; then
			log "mkfs failed ($fs, $b)"
			continue
		fi
		BM_BEG=$(date +%s)

		# Linux: flush caches before we start
		log "echo 3 > /proc/sys/vm/drop_caches" >> "$LOG"/raw/commands.txt
		echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
		run_"$b"
		$DEBUG cd /
		$DEBUG sync
		$DEBUG sleep 5
		$DEBUG sync
		umountfs
		BM_END=$(date +%s)
		BM_DUR=$(echo "scale=2; ( $BM_END - $BM_BEG ) / 60" | bc -l)
		log "Running $b on $fs took $BM_DUR minutes."
	done
	FS_END=$(date +%s)
	FS_DUR=$(echo "scale=2; ( $FS_END - $FS_BEG ) / 60" | bc -l)
	echo
	log "Running all benchmarks on $fs took $FS_DUR minutes."
	echo
done 2>&1 | tee "$LOG"/fs-bench.log

$DEBUG dmesg > "$LOG"/env/dmesg_post.txt
END=$(date +%s)
DUR=$(echo "scale=2; ( $END - $BEGIN ) / 60" | bc -l)
log "Finished after $DUR minutes."

