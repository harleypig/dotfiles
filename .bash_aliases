screen='-t screen -RDl'
port=

# Personal Servers
alias harleypig="ssh ${port} -i ~/.ssh/work_key.dsa -X harleypig.com ${screen}"

# Web Servers
alias builderweb="ssh ${port} 208.110.142.76 ${screen}"
#alias krktrweb="ssh ${port} 208.110.142.44 ${screen}"
alias krktrweb="ssh ${port} 208.110.149.111"
alias merchantweb="ssh ${port} 208.110.135.35 ${screen}"
alias roifweb="ssh ${port} 208.110.149.121 ${screen}"
alias stage6web="ssh ${port} 208.110.142.43 ${screen}"
alias web1="ssh ${port} 208.110.142.41 ${screen}"
#alias web2="ssh ${port} 208.110.142.42 ${screen}"
alias web2="ssh ${port} 208.110.142.74 ${screen}"

# Database Servers
alias archivedb="ssh ${port} 208.110.142.80 ${screen}"
alias builderdb="ssh ${port} 208.110.142.79 ${screen}"
alias krktrdb="ssh ${port} 208.110.149.110"
alias merchantdb="ssh ${port} 208.110.135.34 ${screen}"
alias roifdb="ssh ${port} 208.110.149.122 ${screen}"
alias rootdb="ssh ${port} 208.110.142.75 ${screen}"
alias stage6db="ssh ${port} 208.110.149.113 ${screen}"

alias mysql_archivedb="mysql -h 208.110.142.80 -u harleypig -p"
alias mysql_builderdb="mysql -h 208.110.142.79 -u harleypig -p"
alias mysql_krktrdb="mysql -h 208.110.149.110 -u harleypig -p"
alias mysql_merchantdb="mysql -h 208.110.135.34 -u harleypig -p"
alias mysql_roifdb="mysql -h 208.110.149.122 -u harleypig -p"
alias mysql_rootdb="mysql -h 208.110.142.75 -u harleypig -p"
alias mysql_stage6db="mysql -h 208.110.149.113 -u harleypig -p"
alias mysql_junk="mysql -h 208.110.149.114 -u harleypig -p"

# Misc Servers
alias dev="ssh ${port} 192.168.50.254"
alias shadowman="ssh ${port} 192.168.50.245 ${screen}"
alias fuubar="ssh ${port} cvs.fuubar.com ${screen}"
alias junk="ssh ${port} 208.110.149.114 ${screen}"
alias watchman="ssh ${port} watchman.vankomenmedia.com ${screen}"
alias email="ssh ${port} 208.110.142.84"
