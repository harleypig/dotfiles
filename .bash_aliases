echo Started .bash_aliases ... >> ~/bash_startup.log
# Some of these aliases are:

# from the bash-it project on github: where's the damn url?
# culled from superuser.com

# others are my own fault.

# If ssh config file exists create shortcuts for the hosts defined there

if [ -e ~/.ssh/config ]
then

  # I'm always in screen on my systems.
  # echo -e "\ekHostname\e\" will change the screen title for that tab to the hostname

  pre_title='echo -e "\\ek'
  post_title='\\e\\" && ssh'
  reset='&& echo -e "\\ekbash\\e\\"'
  screen='-t screen -RDl'

  # Personal Servers
  alias harleypig="${pre_title}harleypig.com${post_title} harleypig.com -X ${screen} ${reset}"

  for i in $(grep -E '^Host [^*]' ~/.ssh/config | cut -d ' ' -f 2)
  do
    alias $i="${pre_title}$i${post_title} $i ${reset}"
  done

fi

alias c='clear'
alias -- -="cd -"
alias ..='cd ..'
alias ...='cd ../..'
alias ga='git add'
alias gall='git add .'
alias gba='git branch -a'
alias gb='git branch'
alias gca='git commit -v -a'
alias gc='git commit -v'
alias gco='git checkout'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias gd='git diff | vim -R -'
alias gdv='git diff -w "$@" | vim -R -'
alias gexport='git archive --format zip --output'
alias g='git'
alias g='grep'
alias gl='git pull'
alias gp='git push'
alias gpo='git push origin'
alias gs='git status'
alias h='history'
alias l='ls -lhA --color=auto'
alias md='mkdir -p'
alias rd=rmdir
alias realias='source ~/.bash_aliases'
alias refunction='source ~/.bash_functions'
alias sl=ls
alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
alias fixssh='exec ssh-agent bash'

echo '  ... ended .bash_aliases.' >> ~/bash_startup.log
