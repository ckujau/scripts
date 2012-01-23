#!/bin/sh
#
# (c)2010, lists@nerdbynature.de
#
# Install a new kernel, System.map and .config,
# but not via the usual "make install" routine
#
umask 0022

# unset me!
# DEBUG=echo

if [ ! `id -u` = 0 ]; then
	echo "Please execute as root or use sudo!"
	exit 1
fi

usage() {
echo "Usage: `basename $0`             [directory] [builddir]"
echo "       `basename $0` [user@]host:[directory] [builddir]"
exit 1
}

# set correct arch, imagename
case `uname -m` in
	ppc|ppc64)
	ARCH=powerpc
	IMAGE=zImage
	;;

	x86_64|x86|i686)
	ARCH=x86
	IMAGE=bzImage
	;;
esac

# We need a destination to install to (could be a directory or host:/directory)
if [ -z "$1" ]; then
	usage
fi

# destination is a local directory
if [ -d "$1" ]; then
	MODE=local
	DEST_DIR="$1"
	[ -w "$DEST_DIR" ] || usage

# destination is remote
else
	MODE=remote
	DEST_HOST=`echo $1 | awk -F: '{print $1}'`
	 DEST_DIR=`echo $1 | awk -F: '{print $2}'`
	# Make sure we can resolve our host
	getent hosts `echo $DEST_HOST | sed 's/^.*@//'` > /dev/null || usage
fi

# We might specify a build directory
if   [ -d "$2" -a -x "$2"/vmlinux ]; then
	BUILDDIR="$2"
	OPTIONS="O=$BUILDDIR"

# ...or we omit it, but a vmlinux must be in place then
elif [ -x ./vmlinux ]; then
	BUILDDIR=.

else
	echo "vmlinux not found in $BUILDDIR (no [builddir] specified?)"
	usage
fi

case $MODE in
	remote)
	TDIR=`$DEBUG mktemp -d`
	$DEBUG cp "$BUILDDIR"/vmlinux    "$TDIR"/vmlinux
	$DEBUG cp "$BUILDDIR"/System.map "$TDIR"/System.map
	$DEBUG cp "$BUILDDIR"/.config    "$TDIR"/config

	printf "Do you want to save the current kernel? (Y/n) " && read c
	echo
	if [ "$c" = n ]; then
		echo "Not saving the current kernel!"
	else
		echo "Saving the current kernel on $DEST_HOST:$DEST_DIR..."
		$DEBUG ssh "$DEST_HOST" \
			"mv "$DEST_DIR"/vmlinux    "$DEST_DIR"/vmlinux.old && \
			 mv "$DEST_DIR"/System.map "$DEST_DIR"/System.map.old && \
			 mv "$DEST_DIR"/config     "$DEST_DIR"/config.old"
	fi

	echo
	echo "Copying kernel to $DEST_HOST:$DEST_DIR..."
	$DEBUG scp "$TDIR"/* "$DEST_HOST":"$DEST_DIR"
	$DEBUG rm -rf "$TDIR"
	$DEBUG cd "$BUILDDIR"
	echo
	echo "Installing modules locally..."
	$DEBUG make $OPTIONS modules_install
	;;

	local)
	printf "Do you want to save the current kernel? (Y/n) " && read c
	echo
	if [ "$c" = n ]; then
		echo "Not saving the current kernel!"
	else
		echo "Saving the current kernel in $DEST_DIR..."
		$DEBUG mv "$DEST_DIR"/$IMAGE	"$DEST_DIR"/$IMAGE.old
		$DEBUG mv "$DEST_DIR"/vmlinux	"$DEST_DIR"/vmlinux.old
		$DEBUG mv "$DEST_DIR"/System.map "$DEST_DIR"/System.map.old
		$DEBUG mv "$DEST_DIR"/config	"$DEST_DIR"/config.old
	fi
	$DEBUG cp "$BUILDDIR"/arch/"$ARCH"/boot/$IMAGE	"$DEST_DIR"/$IMAGE && \
	$DEBUG cp "$BUILDDIR"/vmlinux			"$DEST_DIR"/vmlinux && \
	$DEBUG cp "$BUILDDIR"/System.map		"$DEST_DIR"/System.map && \
	$DEBUG cp "$BUILDDIR"/.config			"$DEST_DIR"/config && \
	$DEBUG cd "$BUILDDIR" && \
	$DEBUG make $OPTIONS modules_install
	;;
esac
