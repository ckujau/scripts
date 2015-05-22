#!/bin/sh
#
# (c)2011 lists@nerdbynature.de
# Send SysRq to VirtualBox virtual machines
#
# The schema for sending sysrq keycodes is:
# 1d 38 54 [request type press] [request type release] d4 b8 9d
#
# The 'request type press' are the hex scancodes for a specific character.
#
# For example, to send "s", the 'request type press' is "1f". To release the same
# key, 0x80 is added to the scancode: 0x1f + 0x80 = 0x9f. Thus, the sequence for
# sending sysrq-s is "1f 9f"
#
# Links:
# Keyboard scancodes: Ordinary scancodes
# https://www.win.tue.nl/~aeb/linux/kbd/scancodes-1.html#ss1.4
#
# Re: Magic sysrq on Linux guest, under a Linux host
# https://forums.virtualbox.org/viewtopic.php?f=6&t=10400#p207674
#
# Use Magic Sysrq-key in guest
# http://www.halfdog.net/Misc/TipsAndTricks/VirtualBox.html#MagicSysrq
#
# Switching Linux terminals in VirtualBox using VBoxManage
# http://blog.frameos.org/2011/06/08/changing-linux-terminals-in-virtualbox-using-vboxmanage/
# https://web.archive.org/web/20130102094426/http://blog.frameos.org/2011/06/08/changing-linux-terminals-in-virtualbox-using-vboxmanage
#
if [ ! $# -eq 2 ]; then
	echo "Usage: `basename $0` [vm] [sysrq]"
	echo "                     [vm] help"
	exit 1
else
	   VM="$1"
	SYSRQ="$2"
fi

# From http://www.mjmwired.net/kernel/Documentation/sysrq.txt
PRESS=`echo "
b|30		# reBoot
c|2E		# Crash
e|12		# terminate-all-tasks
f|21		# memory-full-oom-kill
h|23		# help
i|17		# kill-all-tasks
j|24		# thaw-filesystems
k|25		# saK
l|26		# show-backtrace-all-active-cpus
m|32		# show-memory-usage
n|31		# nice-all-RT-tasks
o|18		# powerOff
p|19		# show-registers
q|10		# show-all-timers
r|13		# unRaw
s|1F		# Sync
t|14		# show-task-states
u|16		# Unmount
w|11		# show-blocked-tasks
z|2C		# dump-ftrace-buffer
" | grep "^"$SYSRQ"" | cut -c3,4`

if [ -n "$PRESS" ]; then
	RELEASE=`printf "%X\n" $((0x$PRESS + 0x80))`	# or: 'obase=16; ibase=16; $PRESS + 80 | bc'
	set -x
	VBoxManage controlvm "$VM" keyboardputscancode 1d 38 54 $PRESS $RELEASE d4 b8 9d
else
	echo
	echo "Unknown sysrq key! ("$SYSRQ")"
	egrep '^.\|' $0
	echo
	exit 1
fi
