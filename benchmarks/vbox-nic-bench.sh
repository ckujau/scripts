#!/bin/sh
#
# (c)2017 Christian Kujau <lists@nerdbynature.de>
#
# 6.1. Virtual networking hardware
# https://www.virtualbox.org/manual/ch06.html#nichardware
#
# > vboxmanage --help | grep -A2 nictype
#  --nictype1   Am79C970A	- pcnet  II
#               Am79C973	- pcnet III	- default
#               82540EM		- MT Desktop	- Windows Vista
#               82543GC		-  T Server	- Windows XP
#               82545EM		- MT Server	- OVF imports
#               virtio		- virtio-net	- KVM
#
NICTYPES="Am79C970A Am79C973 82540EM 82543GC 82545EM virtio"

if [ $# -ne 3 ]; then
	echo "Usage: $(basename $0) [vm1] [vm2]         [num]"
	echo "       $(basename $0) [report] [file.log] [num]"
	echo ""
	echo " NOTES:"
	echo " * An iperf3 server MUST be started on vm1 after boot."
	echo " * Password-less logins to and between the VMS needed."
	echo " * Set [num] to 0 for a dry-run"
	echo ""
	echo ""
	exit 1
else
	VM1="$1"
	VM2="$2"
	NUM="$3"
fi

# Short-circuit for reporting mode, because we were too
# lazy to think this through...
if [ "$1" = "report" ]; then
	awk '/Running/ {print $6, $8}' "$2" | while read n1 n2; do
		# This only works when NUM is the same value that we have tested with!
		awk "/$n1 - $n2/ {sum+=\$10} END {print \"$n1 - $n2\t\", sum / 2 / $NUM, \"MB/s\"}" "$2"
	done
	exit $?
fi

# Dry-run?
[ $NUM = 0 ] && DEBUG=echo

die() {
	echo "$@"
	exit 2
}

# We really need this only for the first run, I guess
ison() {
	# running or poweroff/aborted/...?
	STATE=$(VBoxManage showvminfo "$1" --machinereadable | awk -F= '/VMState=/ {print $2}' | sed 's/\"//g')
	if [ "$STATE" = "running" ]; then
		true
	else
		false
	fi
}

for nic2 in $NICTYPES; do
	echo "### NIC2: $nic2 -- shutting down $VM2"
	ison $VM2 && ( $DEBUG VBoxManage controlvm $VM2 acpipowerbutton || die "VBoxManage controlvm $VM2 acpipowerbutton FAILED" )
	$DEBUG sleep 20

	echo "### NIC2: $nic2 -- setting NIC to $nic2 on $VM2"
	$DEBUG VBoxManage modifyvm   $VM2 --nictype1 "$nic2" || die "VBoxManage modifyvm $VM2 --nictype1 "$nic2" FAILED"
	$DEBUG VBoxManage showvminfo $VM2 --machinereadable | grep -A1 -w nic1

	echo "### NIC2: $nic2 -- starting $VM2"
	$DEBUG VBoxManage startvm $VM2 --type headless || die "VBoxManage startvm $VM2 --type headless FAILED"
#	$DEBUG VBoxHeadless --startvm $VM2 &
#	[ $? = 0 ] || die "VBoxHeadless --startvm $VM2 FAILED"
	$DEBUG sleep 30

	for nic1 in $NICTYPES; do
		echo "### NIC1: $nic1 -- shutting down $VM1"
		ison $VM1 && ( $DEBUG VBoxManage controlvm $VM1 acpipowerbutton || die "VBoxManage controlvm $VM1 acpipowerbutton FAILED" )
		$DEBUG sleep 20

		echo "### NIC1: $nic1 -- setting NIC to $nic1 on $VM1"
		ison $VM1 || ( $DEBUG VBoxManage modifyvm $VM1 --nictype1 "$nic1" || die "VBoxManage modifyvm $VM1 --nictype1 "$nic1" FAILED" )
		$DEBUG VBoxManage showvminfo $VM1 --machinereadable | grep -A1 -w nic1

		echo "### NIC1: $nic1 -- starting $VM1"
		$DEBUG VBoxManage startvm $VM1 --type headless || die "VBoxManage startvm $VM1 --type headless FAILED"
#		$DEBUG VBoxHeadless --startvm $VM1 &
#		[ $? = 0 ] || die "VBoxHeadless --startvm $VM1 FAILED"
		$DEBUG sleep 30

		echo "### Running iperf3 tests. NIC1: $nic1 NIC2: $nic2"
		a=1
		while [ $a -le $NUM ] || [ $NUM = 0 ]; do
			echo "### RUN $a of $NUM"
# NAT		#	$DEBUG ssh -p2001 192.168.56.1 "iperf3 -f M -c 10.0.2.5" || die "ssh -p2001 192.168.56.1 ... FAILED"
			$DEBUG ssh $VM2 "iperf3 -f M -T \"$nic1 - $nic2\" -c $VM1" || die "ssh $VM2 -- FAILED"
			[ -z "$DEBUG" ] && a=$((a++1)) || break
		done | egrep 'RUN|ssh|sender|receiver'					# The "ssh" is only matched in $DEBUG mode
		echo
	done
done
