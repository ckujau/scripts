#
# ~/.profile
#
if [ -n "$BASH" -a -f "$HOME"/.bashrc ]; then
	. "$HOME"/.bashrc
fi

umask 0066
