#!/usr/bin/env sh
# ~/.ashrc: executed by bash(1) for non-login shells.

# You may uncomment the following lines if you want `ls' to be colorized:
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
#

# Some more alias to avoid making mistakes:
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
#

# Magento 2 alias
alias m2='$DOCUMENT_ROOT/bin/magento'
alias mcc='m2 cache:clean'
alias mcf='m2 cache:flush'
alias msu='m2 setup:upgrade'
#
