#
# ~/.profile
#
umask 0066

export TERM='xterm-color'
export PAGER='less'
export LESS='--ignore-case --squeeze-blank-lines --no-init --RAW-CONTROL-CHARS'
export EDITOR='vi'

# For some reason, pdksh doesn't execute ~/.kshrc when ENV is not set.
echo $SHELL | grep -q ksh && export ENV=$HOME/.kshrc
