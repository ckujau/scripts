#!/bin/sh -e
#
# (c)2019 Christian Kujau <lists@nerdbynature.de>
# Start/stop an IPsec tunnel with iproute2
#
# Inspired by:
# > vishvananda/tunnel.sh
# > https://gist.github.com/vishvananda/7094676
#
# > “On the fly” IPsec VPN with iproute2
# > https://backreference.org/2014/11/12/on-the-fly-ipsec-vpn-with-iproute2/
#
if [ $# -ne 7 ] || [ ! -f "$HOME/.xfrm-keys" ]; then
	echo "Usage: $(basename "$0") [SRC LOCAL DEV] [DST REMOTE DEV] [start|stop|status]"
	echo " Note: We also need a key file in \$HOME/.xfrm-keys, with NN bit keys and"
	echo "       a 32 bit id, generated like this:"
	echo ""
	echo "CIPHER=\"[blowfish|rfc3686(ctr(aes))|...]\""
	echo "  KEY1=0x\$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | xxd -c 256 -p)"
	echo "  KEY2=0x\$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | xxd -c 256 -p)"
	echo "    ID=0x\$(dd if=/dev/urandom bs=1 count=4  2>/dev/null | xxd -c 256 -p)"
	echo ""
	exit 1
else
	   SRC=$1
	 LOCAL=$2
	  DEVL=$3
	   DST=$4
	REMOTE=$5
	  DEVR=$6
	ACTION=$7
fi

# Read keys
eval $(grep -v ^\# "$HOME"/.xfrm-keys)
if [ -z "$CIPHER" ] || [ -z "$KEY1" ] || [ -z "$KEY2" ] || [ -z "$ID" ]; then
	echo "Could not read cipher/keys from $HOME/.xfrm-keys!"
	exit 1
fi

# unset me!
# DEBUG=echo
# echo "DEBUG: SRC: $SRC LOCAL: $LOCAL DEVL: $DEVL / DST: $DST REMOTE: $REMOTE DEVR: $DEVR"

case $ACTION in
	start)
	# XFRM
	$DEBUG ip xfrm state  add src "$SRC"    dst "$DST"    proto esp spi "$ID" reqid "$ID" mode tunnel auth sha256 "$KEY1" enc "$CIPHER" "$KEY2"
	$DEBUG ip xfrm state  add src "$DST"    dst "$SRC"    proto esp spi "$ID" reqid "$ID" mode tunnel auth sha256 "$KEY1" enc "$CIPHER" "$KEY2"
	$DEBUG ip xfrm policy add src "$LOCAL"  dst "$REMOTE" dir out tmpl src "$SRC" dst "$DST" proto esp reqid "$ID" mode tunnel
	$DEBUG ip xfrm policy add src "$REMOTE" dst "$LOCAL"  dir in  tmpl src "$DST" dst "$SRC" proto esp reqid "$ID" mode tunnel

	# Routing
	$DEBUG ip addr  add "$LOCAL"/32  dev lo
	$DEBUG ip route add "$REMOTE"/32 dev "$DEVL" src "$LOCAL"

	# And again on the remote side
	ssh "$DST" /bin/sh -x << EOF
	    # XFRM
	    $DEBUG ip xfrm state  add src $SRC    dst $DST    proto esp spi $ID reqid $ID mode tunnel auth sha256 $KEY1 enc "$CIPHER" $KEY2
	    $DEBUG ip xfrm state  add src $DST    dst $SRC    proto esp spi $ID reqid $ID mode tunnel auth sha256 $KEY1 enc "$CIPHER" $KEY2
	    $DEBUG ip xfrm policy add src $REMOTE dst $LOCAL  dir   out tmpl src $DST dst $SRC proto esp reqid $ID mode tunnel
	    $DEBUG ip xfrm policy add src $LOCAL  dst $REMOTE dir   in  tmpl src $SRC dst $DST proto esp reqid $ID mode tunnel
	    # Routing
	    $DEBUG ip addr  add $REMOTE/32 dev lo
	    $DEBUG ip route add $LOCAL/32  dev $DEVR src $REMOTE
EOF
	;;

	stop)
	# Remote
	ssh "$DST" /bin/sh -x << EOF
	    # Routing
	    $DEBUG ip route del $LOCAL/32  dev $DEVR src $REMOTE
	    $DEBUG ip addr  del $REMOTE/32 dev lo
	    # XFRM
	    $DEBUG ip xfrm policy del src $LOCAL  dst $REMOTE dir   in
	    $DEBUG ip xfrm policy del src $REMOTE dst $LOCAL  dir   out
	    $DEBUG ip xfrm state  del src $DST    dst $SRC    proto esp spi $ID
	    $DEBUG ip xfrm state  del src $SRC    dst $DST    proto esp spi $ID
EOF
	# Routing
	$DEBUG ip route del "$REMOTE"/32 dev "$DEVL" src "$LOCAL"
	$DEBUG ip addr  del "$LOCAL"/32  dev lo

	# XFRM
	$DEBUG ip xfrm policy del src "$REMOTE" dst "$LOCAL"  dir in
	$DEBUG ip xfrm policy del src "$LOCAL"  dst "$REMOTE" dir out
	$DEBUG ip xfrm state  del src "$DST"    dst "$SRC"    proto esp spi "$ID"
	$DEBUG ip xfrm state  del src "$SRC"    dst "$DST"    proto esp spi "$ID"
	;;

	status)
	$DEBUG ip xfrm state && ip xfrm policy
	echo
	ssh "$DST" /bin/sh -x << EOF
		$DEBUG ip xfrm state && ip xfrm policy
EOF
	;;
esac
