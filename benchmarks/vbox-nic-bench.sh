#!/bin/sh
#
# (c)2015 Christian Kujau <lists@nerdbynature.de>
# Some kind of network benchmark for VirtualBox machines
#
# Needed:
# * Guest VM with static IP addresses all set up. The trick is to get the VM
#   to aquire network connectivity, even if the interfaces changes. Magic boot
#   routines trying to guess the correct NIC may cause trouble.
# * password-less SSH (root) login to the guest VM
# * iperf2 installed on the host and the guest VM
# * netcat(1) (use the MacPorts variant for a MacOS X host!)
#

# unset me!
# DEBUG=echo

# https://www.virtualbox.org/manual/ch06.html#nichardware
#
# Am79C970A	- AMD PCNet PCI II
# Am79C973	- AMD PCNet FAST III (default)
# 82540EM	- Intel PRO/1000 MT Desktop (works with Windows Vista)
# 82543GC	- Intel PRO/1000 T Server (recognized by Windows XP)
# 82545EM	- Intel PRO/1000 MT (for OVF imports from other platforms)
# virtio	- virtio-net (supported by Linux 2.6.25 and Windows, see
#		  http://www.linux-kvm.org/page/WindowsGuestDrivers)
#
TYPES="Am79C970A virtio"					# test
TYPES="Am79C970A Am79C973 82540EM 82543GC 82545EM virtio"
	
_help() {
echo "Usage: $(basename $0) [vm] [time]"
echo "       $(basename $0) [report] [file]"
exit 1
}

case $1 in
	report)
	[ -f "$2" ] && REPORT="$2" || _help

	echo "### By NIC type:"
	for t in $TYPES; do 
		for m in hostonly bridged natnetwork nat; do
			printf "NIC: $t / MODE: $m  "
			RESULT=$(grep -A7 "iperf: $m / NIC: $t" "$REPORT" | awk '/Bytes\/sec/ {print $(NF-1), $NF}')
			[ -n "$RESULT" ] && echo "$RESULT" || echo "-"
		done | sort -rnk6
		echo
	done

	echo
	echo "### By network mode:"
	for m in hostonly bridged natnetwork nat; do
		for t in $TYPES; do
			printf "NIC: $t / MODE: $m  "
			RESULT=$(grep -A7 "iperf: $m / NIC: $t" "$REPORT" | awk '/Bytes\/sec/ {print $(NF-1), $NF}')
			[ -n "$RESULT" ] && echo "$RESULT" || echo "-"
		done | sort -rnk6
		echo
	done
	exit $?
	;;

	[a-z]*)
	$DEBUG VBoxManage showvminfo "$1" > /dev/null 2>&1 || _help
	  VM="$1"
	TIME="${2:-10}"			# How long to run "iperf"
	;;
	
	*)
	_help
	;;
esac

_stop_vm() {
echo "INFO: Sending shutdown signal to "$VM"..."
$DEBUG VBoxManage controlvm "$VM" acpipowerbutton

echo "INFO: Wait until $VM is powered off..."
i=0
state="running"
ERROR=0

# Bail out after 2 minutes
while true; do
	state=`VBoxManage showvminfo "$VM" --machinereadable | awk -F= '/^VMState=/ {print $2}' | sed 's/"//g'`
	if [ "$state" = "poweroff" ]; then
		echo "INFO: vm $VM state: $state"
		break
	else
		echo "INFO: vm $VM state: $state"

		if [ $i -gt 40 ]; then
			echo "ERROR: timeout reached, sending poweroff..."
			$DEBUG VBoxManage controlvm "$VM" poweroff || ERROR=1
		fi
	fi

	sleep 3
	i=$((i+1))
done
}

wait_until_ssh() {
j=0
state="running"
ERROR=0

while true; do
	# NOTE: On MacOS X, the stock netcat version does not timeout even when
	# the -w1 option is given. We'll use the MacPorts version for that.
	PATH=/opt/local/bin:$PATH nc -w1 -z "$VM" 22 > /dev/null 2>&1 && break
	echo "INFO: vm $VM still not reachable via SSH"

	# Bail out after 2 minutes
	if [ $j -gt 40 ]; then
		ERROR=1
		echo "ERROR: timeout reached!"
		break
	fi

	sleep 3
	j=$((j+1))
done
}

$DEBUG _stop_vm
if [ $ERROR = 1 ]; then
	echo "ERROR: could not stop VM, bailing out"
	exit 3
fi
$DEBUG sleep 2

echo "INFO: Prepare NAT networking..."
$DEBUG VBoxManage natnetwork remove --netname natnet1
$DEBUG VBoxManage natnetwork add    --netname natnet1 --network 192.168.15.0/24
$DEBUG VBoxManage natnetwork stop   --netname natnet1
$DEBUG VBoxManage natnetwork modify --netname natnet1 --dhcp off \
	--port-forward-4 'iperf:tcp:[127.0.0.1]:15001:[192.168.15.4]:5001' \
	--port-forward-4 'ssh:tcp:[127.0.0.1]:15002:[192.168.15.4]:22' \
	--port-forward-4 'foo:tcp:[127.0.0.1]:15003:[192.168.15.4]:1234'
$DEBUG VBoxManage natnetwork start --netname natnet1

for nic in $TYPES; do
	$DEBUG _stop_vm
	[ $ERROR = 1 ] && continue

	$DEBUG sleep 2

	echo
	echo "####### NIC: $nic"

	echo "The VM $VM should be powered off now, let's configure 4 NICs..."
	$DEBUG VBoxManage modifyvm "$VM" --natpf4 delete iperf --natpf4 delete ssh --natpf4 delete foo

	# VirtualBox MAC address prefix is 08-00-27. Our NIC1 should already be configured and we don't
	# want to change the MAC address here. Let's change it only for NIC2/3/4

	# We also need to find out our primay network interface for "bridged" mode.
	case $(uname -s) in
		Darwin)
		DEV=$(netstat -rn -f inet | awk '/^default/ {print $NF}')
		;;

		Linux)
		DEV=$(netstat -rn -A inet | awk '/^0.0.0.0/ {print $NF}')
		;;

		*)
		echo "Which platform are we on?"
		exit 2
	esac

	$DEBUG VBoxManage modifyvm "$VM" \
		--nic1 hostonly   --hostonlyadapter1 vboxnet0 --nictype1 "$nic" \
		--nic2 bridged    --bridgeadapter2   $DEV     --nictype2 "$nic" --macaddress2 080027e20002 \
		--nic3 natnetwork --nat-network3     natnet1  --nictype3 "$nic" --macaddress3 080027e20003 \
		--nic4 nat        --natnet4      10.0.2.0/24  --nictype4 "$nic" --macaddress4 080027e20004 \
			--natpf4 "iperf,tcp,127.0.0.1,25001,10.0.2.123,5001" \
			--natpf4 "ssh,tcp,127.0.0.1,25002,10.0.2.123,22" \
			--natpf4 "foo,tcp,127.0.0.1,25003,10.0.2.123,1234"
	$DEBUG sleep 2

	# This should give us 4 NICs in the VM:
	# 
	# NIC1	- eth0 - hostonly	- 192.168.56.0/24 (default)
	# NIC2	- eth1 - bridged	- 192.168.0.0/24
	# NIC3	- eth2 - natnetwork	- 192.168.15.0/24
	# NIC4	- eth3 - nat		- 10.0.2.0/24
	#
	# FIXME: for now we have static NIC names and static IP addresses. More logic
	# is needed to have all this configured dynamically.
	#
	# - /etc/udev/rules.d/70-persistent-net.rules
	# SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="08:00:27:??:??:??", KERNEL=="eth*", NAME="eth0"
	# SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="08:00:27:e2:00:02", KERNEL=="eth*", NAME="eth1"
	# SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="08:00:27:e2:00:03", KERNEL=="eth*", NAME="eth2"
	# SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="08:00:27:e2:00:04", KERNEL=="eth*", NAME="eth3"
	#
	# - /etc/network/interfaces
	#
	# auto lo eth0 eth1 eth2 eth3
	# # host-only
	# iface eth0 inet dhcp
	#
	# # bridged
	# # The /32 may be needed when we're in the same network as eth0 and we
	# # don't want a second network route
	# iface eth1 inet static
	#    address 192.168.0.123
	#    netmask 255.255.255.255
	#
	# # nat-network
	# iface eth2 inet static
	#    address 192.168.15.123
	#    netmask 255.255.255.0
	#
	# # nat
	# iface eth3 inet static
	#    address 10.0.2.123
	#    netmask 255.255.255.0
	#

	echo "Start the VM..."
	$DEBUG VBoxManage startvm "$VM" --type headless

	echo "Wait until SSH comes up..."
	$DEBUG wait_until_ssh
	[ $ERROR = 1 ] && continue
	$DEBUG sleep 2

	echo "The VM should be accessible via SSH now."
	echo
	$DEBUG ssh "$VM" "uname -a; lspci | grep net; iperf --server --daemon > /var/log/iperf-server_"$nic".log"
	$DEBUG sleep 2

	echo
	echo "### iperf: hostonly / NIC: $nic"
	$DEBUG iperf -f M -t $TIME -c "$VM"

	echo
	echo "### iperf: bridged / NIC: $nic"
	[ -z "$DEBUG" ] && IP_BR=$(ssh "$VM" "ip -4 addr show eth1 | awk '/inet/ {print \$2}' | sed 's|/[0-9]*||'")
	$DEBUG iperf -f M -t $TIME -c "$IP_BR"

	echo
	echo "### iperf: natnetwork / NIC: $nic"
	$DEBUG iperf -f M -t $TIME -c 127.0.0.1 -p 15001

	echo
	echo "### iperf: nat / NIC: $nic"
	$DEBUG iperf -f M -t $TIME -c 127.0.0.1 -p 25001
	echo

	echo "Saving the VM's dmesg..."
	$DEBUG ssh "$VM" dmesg > vbox_"$VM"_"$nic"_dmesg.txt

	$DEBUG sleep 2

	$DEBUG _stop_vm
	[ $ERROR = 1 ] && continue

	$DEBUG sleep 2
	echo
done
