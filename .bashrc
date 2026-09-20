#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
alias battery="upower -i /org/freedesktop/UPower/devices/battery_BAT0"


# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/xtrmn8/.lmstudio/bin"
# End of LM Studio CLI section


