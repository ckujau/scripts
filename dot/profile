#
# ~/.profile
#
umask 0066

export TERM='xterm'
export PAGER='less'
export LESS='--ignore-case --squeeze-blank-lines --no-init --RAW-CONTROL-CHARS'
export EDITOR='vi'

# For some reason, pdksh doesn't execute ~/.kshrc when ENV is not set.
echo $SHELL | grep ksh > /dev/null && export ENV=$HOME/.kshrc
