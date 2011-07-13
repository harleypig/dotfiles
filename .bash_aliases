#echo Started .bash_aliases ... >> ~/bash_startup.log
# Some of these aliases are:

# from the bash-it project on github: where's the damn url?
# culled from superuser.com

# others are my own fault.

# If ssh config file exists create shortcuts for the hosts defined there

if [ -e ~/.ssh/config ]
then

  # XXX: Ignore, or otherwise handle, wildcard hosts (e.g., facelift*)

  # XXX: Make a function that checks if a master connection is made and, if
  # not, create one and background it so as to avoid accidental disconnections
  # (which would disconnect *all* current connections).
  #
  # Background connection:
  #   http://rc.fas.harvard.edu/tipsntricks/sshcontrolmaster
  #   ssh -Y -C -o ServerAliveInterval=30 -fN ody
  #
  # Detecting existing ControlMaster session:
  #   http://serverfault.com/questions/211213/how-to-tell-if-an-ssh-controlmaster-connection-is-in-use
  #   ssh -o ControlPath=$socket -O check
  #   Other goodness there.

  # I'm always in screen on my systems.
  # Should still check if we are in screen.  How?
  # echo -e "\ekHostname\e\" will change the screen title for that tab to the hostname

  pre_title='echo -e "\\ek'
  post_title='\\e\\" && ssh'
  reset='&& echo -e "\\ekbash\\e\\"'
  screen='-t screen -RDl'

  for i in $(grep -E '^Host ' ~/.ssh/config | grep -v '*' | cut -d ' ' -f 2)
  do
    alias $i="${pre_title}$i${post_title} $i ${reset}"
  done

  # Override basic settings for these servers
  alias harleypig="${pre_title}harleypig.com${post_title} harleypig -X ${screen} ${reset}"

fi

# Git
alias ga='git add'
alias gall='git add .'
alias gba='git branch -a -v'
alias gb='git branch'
alias gca='git commit -a -v'
alias gc='git commit -v'
alias gco='git checkout'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias gd='git diff | vim -R -'
alias gdv='git diff -w "$@" | vim -R -'
alias gexport='git archive --format zip --output'
alias git_remove_missing_files="git status | awk '/deleted:(.*)/ {print $3}' | xargs git rm"
alias gl='git pull'
alias gmv='git mv'
alias gp='git push'
alias gpo='git push origin'
alias gpall='git push all --all'
alias grm='git rm'
alias gs='git status -s'
alias gwtf='git-wtf'

# Apache
alias acconfigtest="sudo $(which apachectl) configtest"
alias acrestart="sudo $(which apachectl) stop ; sleep 3 ; sudo $(which apachectl) start"
alias acstart="sudo $(which apachectl) start"
alias acstop="sudo $(which apachectl) stop"
alias tail_apache_logs='tail -f /home/www/apache2/logs/error.log /home/www/harleypig.com/logs/error.log'

# FBcmd
alias fb='fbcmd'

# System
alias c='clear'
alias -- -="cd -"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias g='grep'
alias h='history'
alias l='ls -lhA --color=auto'
alias md='mkdir -p'
alias rd=rmdir
alias realias='source ~/.bash_aliases'
alias refunction='source ~/.bash_functions'
alias sl=ls
alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"

# Kludges
alias fixssh='exec ssh-agent bash'

# Mechanize Shell
alias mechsh='perl -MWWW::Mechanize::Shell -eshell'

#echo '  ... ended .bash_aliases.' >> ~/bash_startup.log
