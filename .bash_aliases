port=
post_title='\\e\\" && ssh'
pre_title='echo -e "\\ek'
reset='&& echo -e "\\ekbash\\e\\"'
screen='-t screen -RDl'

# Personal Servers
alias harleypig="${pre_title}harleypig.com${post_title} harleypig.com -X ${screen} ${reset}"

for i in $(grep -E '^Host [^*]' .ssh/config | cut -d ' ' -f 2)
do
  alias $i="${pre_title}$i${post_title} $i ${reset}"
done
