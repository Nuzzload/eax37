# ~/.bashrc — EAX-37 shell config

export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
export EDITOR=nano
export HISTFILE=~/.bash_history
export HISTSIZE=1000
export PATH="$PATH:~/tools"

alias ll='ls -la'
alias cls='clear'
alias c='clear'

# ne pas laisser de traces
HISTCONTROL=ignoredups:ignorespace