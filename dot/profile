#
# ~/.profile
#
if [ -n "$BASH" -a -f "$HOME"/.bashrc ]; then
	. "$HOME"/.bashrc
fi

if [ "$0" = "-ksh" -a -f "$HOME"/.kshrc ]; then
	ENV="$HOME/.kshrc"
	export ENV
fi

if [ -n "$ZSH_VERSION" -a -f "$HOME"/.zshrc ]; then
	. "$HOME"/.zshrc
fi

umask 0066
