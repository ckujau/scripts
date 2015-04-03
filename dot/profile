#
# ~/.profile
#
umask 0066

export TERM=xterm-color
export PAGER='less'
export LESS='--ignore-case --squeeze-blank-lines --no-init --RAW-CONTROL-CHARS'
export EDITOR=vi

alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'

# GREP_OPTIONS has been marked obsolete
# http://debbugs.gnu.org/cgi/bugreport.cgi?bug=19998
if grep --version 2>/dev/null | egrep -q 'GNU|BSD' 2>/dev/null; then
	alias   grep='grep   --color=auto --devices=skip'
	alias  egrep='egrep  --color=auto --devices=skip'
	alias  fgrep='fgrep  --color=auto --devices=skip'
	alias  zgrep='zgrep  --color=auto --devices=skip'
	alias bzgrep='bzgrep --color=auto --devices=skip'
	alias xzgrep='xzgrep --color=auto --devices=skip'
fi

# Source shell specifics
if [ -n "$BASH" -a -f "$HOME"/.bashrc ]; then
	. "$HOME"/.bashrc
fi

if [ "$0" = "-ksh" -a -f "$HOME"/.kshrc ]; then
	ENV="$HOME/.kshrc"
	export ENV
fi

# ZSH uses .zprofile instead of .profile, so we need a symlink before this works
if [ -n "$ZSH_VERSION" -a -f "$HOME"/.zshrc ]; then
	. "$HOME"/.zshrc
fi
