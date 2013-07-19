l templates/snippet/
vim templates/snippet/html_title.tt 
ga templates/
gc 'copied templates from Blio repo'
vim templates/*.tt
l templates/
vim $(which blio.pl)
ga src/index.txt 
gc 'added notes to myself for this first blog post'
gp
l lib
l lib/Blio
dzil clean
grep -r 'Template' *
ga .gitignore 
gc 'ignore .build and generated cpan dir and tarball'
ga lib/Blio.pm 
gc 'modified to use Template::Alloy'
vim t/Blio/tree.t 
grep -r utf8
grep -r utf8 *
grep -r binmode
grep -r binmode *
perldoc binmode
grep -ri binmode *
vim lib/Blio/Node.pm 
perldoc -f binmode
vim /usr/local/share/perl/5.10.1/Template/Alloy/TT.pm +518
cpanm gitpan
cd
cd projects/
mkdir Template-Alloy
cd Template-Alloy/
wget http://cpan.metacpan.org/authors/id/R/RH/RHANDOM/Template-Alloy-1.016.tar.gz
tar xvf Template-Alloy-1.016.tar.gz 
rm -fr Template-Alloy-1.016.tar.gz 
mv Template-Alloy-1.016/* .
rmdir Template-Alloy-1.016/
git init
gall
gc 'initial commit of 1.016 from the cpan'
git remote add origin git@github.com:harleypig/Template-Alloy.git
git push origin master
git tag v1.1016
gco -b fix_binmode_utf8
l lib/Template/Alloy/TT.pm 
vim lib/Template/Alloy/TT.pm 
ga lib/Template/Alloy/TT.pm 
gc 'ripped off TemplateToolkits fix for the binmode layers option'
perl Makefile.PL 
make ; make test
vim .gitignore
ga .gitignore
gc 'ignored generated files'
glg
sudo make install
cdl ../Blio/
cdl ../Template-Alloy/
gs
gco master
gco -b mybranch
git merge fix_binmode_utf8
git push
git push --all
cd master/
vim src/index.txt 
cdl ../blog_perl/
cd master
dzil test
vim $(perldoc Blio)
vim lib/Blio
sudo dzil install
cdl ../blog_perl/master/
l
l ../gh-pages/
vim templates/wrapper.tt 
./build 
cdl ../../Blio/
grep -r writing *
vim lib/Blio.pm 
cd ../blog_perl/master
vim $(perldoc -l Blio)
cd ../../Blio/
grep -r nodes_by_url *
cd ../blog_perl/master/
perl -d $(which blio.pl)
vim ../gh-pages/index.html 
gtl
grep autochdir -ri *
exit
cpanm Dist::Zilla
perl_blog
mkdir perl_blog
cd perl_blog/
git clone git://github.com/domm/Blio.git
cd Blio/
cat readme.txt 
l .build
l latest
cat .gitignore 
dzil build
gb -ra
gl
dzil authordeps
dzil authordeps | cpanm
dzil
dzil listdeps
dzil listdeps | cpanm
dzil listdeps > deps
sh deps 
vim deps
sh deps
cd ~/.cpanm/
alias cpanm
cpanm HTML::BBCode Text::Textile HTML::Truncate
cpanm Markup::Unified
cd .cpanm/
cd latest-build
cat build.log 
cd Markup-Unified-0.0401/
make distclean
make
make test
vim t/01-format_bbcode.t 
cpanm Module::Metadata
l .cpanm/latest-build
l .cpanm/latest-build/
cpanm Markup::Unified --force
cd projects/Blio/
git lg
rm deps
vim .gitignore 
dzil install
mv perl_blog blog_perl
curl -s https://lv.linode.com/sYQx | sudo bash
git help init
git help branch
git branch -m gh-pages
l out
vim out/index.html 
git branch -m master
l .git/refs/heads/
ga blio.ini src
gc -m 'added ini file and initial index text'
gc 'added ini file and initial index text'
git help checkout
blio.pl -h
git rm blio.ini
rm -fr out
blio.pl --help
gc -m 'ini file not needed in gh-pages branch'
gc 'ini file not needed in gh-pages branch'
git rm CNAME
gc 'CNAME file not needed in master branch'
gco gh-pages
l src
rm -fr blog_perl
mkdir blog_perl
cd blog_perl/
mkdir master
echo 'This is the master branch for my perl blog repo.' > README.markdown
git add README.markdown
gc 'initial commit'
git remote add origin git@github.com:harleypig/blog_perl.git
git push -u origin master
..
mkdir gh-pages
cd gh-pages/
git clone git@github.com:harleypig/blog_perl.git .
git checkout origin/gh-pages -b gh-pages
gco -b gh-pages
gb
git rm README.markdown
vim CNAME
ga CNAME 
gc 'added cname file'
cd ../master/
mkdir src
> blio.ini
vim src/index.txt
ga blio.ini src/
gc 'added blio ini file and initial post'
blio.pl --output_dir ../gh-pages
cd ../gh-pages/
ga index.html 
gc 'initial add of index page'
cd projects/blog_perl/
vim build
ga build 
gc 'added build script to automate steps needed to update gh-pages'
man blio.pl
vim build 
l \'../
rm -fr \'../
vim blio.ini 
blio.pl 
blio.pl
l ../gh-pages/index.html 
cat ../gh-pages/index.html 
ga blio.ini build src/index.txt 
gc 'setup the ini file, modify the build script, change the index.txt file to make sure everything was sstill working'
cat build 
l ../../Blio/share/templates/
mkdir templates
cp -R ../../Blio/share/templates/* templates/
l templates/snippet/
vim templates/snippet/html_title.tt 
ga templates/
gc 'copied templates from Blio repo'
vim templates/*.tt
l templates/
vim $(which blio.pl)
ga src/index.txt 
gc 'added notes to myself for this first blog post'
gp
l lib
l lib/Blio
dzil clean
grep -r 'Template' *
ga .gitignore 
gc 'ignore .build and generated cpan dir and tarball'
ga lib/Blio.pm 
gc 'modified to use Template::Alloy'
vim t/Blio/tree.t 
grep -r utf8
grep -r utf8 *
grep -r binmode
grep -r binmode *
perldoc binmode
grep -ri binmode *
vim lib/Blio/Node.pm 
perldoc -f binmode
vim /usr/local/share/perl/5.10.1/Template/Alloy/TT.pm +518
cpanm gitpan
cd
cd projects/
mkdir Template-Alloy
cd Template-Alloy/
wget http://cpan.metacpan.org/authors/id/R/RH/RHANDOM/Template-Alloy-1.016.tar.gz
tar xvf Template-Alloy-1.016.tar.gz 
rm -fr Template-Alloy-1.016.tar.gz 
mv Template-Alloy-1.016/* .
rmdir Template-Alloy-1.016/
git init
gall
gc 'initial commit of 1.016 from the cpan'
git remote add origin git@github.com:harleypig/Template-Alloy.git
git push origin master
git tag v1.1016
gco -b fix_binmode_utf8
l lib/Template/Alloy/TT.pm 
vim lib/Template/Alloy/TT.pm 
ga lib/Template/Alloy/TT.pm 
gc 'ripped off TemplateToolkits fix for the binmode layers option'
perl Makefile.PL 
make ; make test
vim .gitignore
ga .gitignore
gc 'ignored generated files'
glg
sudo make install
cdl ../Blio/
cdl ../Template-Alloy/
gs
gco master
gco -b mybranch
git merge fix_binmode_utf8
git push
git push --all
cd master/
vim src/index.txt 
cdl ../blog_perl/
cd master
dzil test
vim $(perldoc Blio)
vim lib/Blio
sudo dzil install
cdl ../blog_perl/master/
l
l ../gh-pages/
./build 
cdl ../../Blio/
grep -r writing *
vim lib/Blio.pm 
cd ../blog_perl/master
vim $(perldoc -l Blio)
cd ../../Blio/
grep -r nodes_by_url *
cd ../blog_perl/master/
perl -d $(which blio.pl)
vim ../gh-pages/index.html 
vim templates/wrapper.tt 
grep autochdir -ri *
gtl
grep autochdir -ri *
exit
cpanm Dist::Zilla
perl_blog
mkdir perl_blog
cd perl_blog/
git clone git://github.com/domm/Blio.git
cd Blio/
cat readme.txt 
l .build
l latest
cat .gitignore 
dzil build
gb -ra
gl
dzil authordeps
dzil authordeps | cpanm
dzil
dzil listdeps
dzil listdeps | cpanm
dzil listdeps > deps
sh deps 
vim deps
sh deps
cd ~/.cpanm/
alias cpanm
cpanm HTML::BBCode Text::Textile HTML::Truncate
cpanm Markup::Unified
cd .cpanm/
cd latest-build
cat build.log 
cd Markup-Unified-0.0401/
make distclean
make
make test
vim t/01-format_bbcode.t 
cpanm Module::Metadata
l .cpanm/latest-build
l .cpanm/latest-build/
cpanm Markup::Unified --force
cd projects/Blio/
git lg
rm deps
vim .gitignore 
dzil install
mv perl_blog blog_perl
curl -s https://lv.linode.com/sYQx | sudo bash
git help init
git help branch
git branch -m gh-pages
l out
vim out/index.html 
git branch -m master
l .git/refs/heads/
ga blio.ini src
gc -m 'added ini file and initial index text'
gc 'added ini file and initial index text'
git help checkout
blio.pl -h
git rm blio.ini
rm -fr out
blio.pl --help
gc -m 'ini file not needed in gh-pages branch'
gc 'ini file not needed in gh-pages branch'
git rm CNAME
gc 'CNAME file not needed in master branch'
gco gh-pages
l src
rm -fr blog_perl
mkdir blog_perl
cd blog_perl/
mkdir master
echo 'This is the master branch for my perl blog repo.' > README.markdown
git add README.markdown
gc 'initial commit'
git remote add origin git@github.com:harleypig/blog_perl.git
git push -u origin master
..
mkdir gh-pages
cd gh-pages/
git clone git@github.com:harleypig/blog_perl.git .
git checkout origin/gh-pages -b gh-pages
gco -b gh-pages
gb
git rm README.markdown
vim CNAME
ga CNAME 
gc 'added cname file'
cd ../master/
mkdir src
> blio.ini
vim src/index.txt
ga blio.ini src/
gc 'added blio ini file and initial post'
blio.pl --output_dir ../gh-pages
cd ../gh-pages/
ga index.html 
gc 'initial add of index page'
cd projects/blog_perl/
vim build
ga build 
gc 'added build script to automate steps needed to update gh-pages'
man blio.pl
vim build 
l \'../
rm -fr \'../
vim blio.ini 
blio.pl
l ../gh-pages/index.html 
cat ../gh-pages/index.html 
ga blio.ini build src/index.txt 
gc 'setup the ini file, modify the build script, change the index.txt file to make sure everything was sstill working'
cat build 
l ../../Blio/share/templates/
mkdir templates
cp -R ../../Blio/share/templates/* templates/
l templates/snippet/
vim templates/snippet/html_title.tt 
ga templates/
gc 'copied templates from Blio repo'
vim templates/*.tt
l templates/
vim $(which blio.pl)
ga src/index.txt 
gc 'added notes to myself for this first blog post'
gp
l lib
l lib/Blio
dzil clean
grep -r 'Template' *
ga .gitignore 
gc 'ignore .build and generated cpan dir and tarball'
ga lib/Blio.pm 
gc 'modified to use Template::Alloy'
vim t/Blio/tree.t 
grep -r utf8
grep -r utf8 *
grep -r binmode
grep -r binmode *
perldoc binmode
grep -ri binmode *
vim lib/Blio/Node.pm 
perldoc -f binmode
vim /usr/local/share/perl/5.10.1/Template/Alloy/TT.pm +518
cpanm gitpan
cd
cd projects/
mkdir Template-Alloy
cd Template-Alloy/
wget http://cpan.metacpan.org/authors/id/R/RH/RHANDOM/Template-Alloy-1.016.tar.gz
tar xvf Template-Alloy-1.016.tar.gz 
rm -fr Template-Alloy-1.016.tar.gz 
mv Template-Alloy-1.016/* .
rmdir Template-Alloy-1.016/
git init
gall
gc 'initial commit of 1.016 from the cpan'
git remote add origin git@github.com:harleypig/Template-Alloy.git
git push origin master
git tag v1.1016
gco -b fix_binmode_utf8
l lib/Template/Alloy/TT.pm 
vim lib/Template/Alloy/TT.pm 
ga lib/Template/Alloy/TT.pm 
gc 'ripped off TemplateToolkits fix for the binmode layers option'
perl Makefile.PL 
make ; make test
vim .gitignore
ga .gitignore
gc 'ignored generated files'
glg
sudo make install
cdl ../Blio/
cdl ../Template-Alloy/
gs
gco master
gco -b mybranch
git merge fix_binmode_utf8
git push
git push --all
cd master/
vim src/index.txt 
cdl ../blog_perl/
cd master
dzil test
vim $(perldoc Blio)
vim lib/Blio
sudo dzil install
cdl ../blog_perl/master/
l
l ../gh-pages/
./build 
cdl ../../Blio/
grep -r writing *
vim lib/Blio.pm 
cd ../blog_perl/master
vim $(perldoc -l Blio)
cd ../../Blio/
grep -r nodes_by_url *
cd ../blog_perl/master/
perl -d $(which blio.pl)
vim ../gh-pages/index.html 
vim templates/wrapper.tt 
blio.pl 
metacpan_namespace.pl --module Class::DBI --size 20
metacpan_namespace.pl DBIx::Closs --size=20
metacpan_namespace.pl --module DBIx::Class --size 20
vance
vance
vim .ssh/config
vance
vim .ssh/config
exit
cvs
cd projects/dot_vim/
git diff .vim/bundle/settings/after/plugin/plugin_settings.vim
cd .vim/bundle/settings/
mkdir ftplugin
cd ftplugin/
vim help.vim
gtl
vim .vimrc
gs
git diff .vimrc
vim .vim/bundle/settings/after/plugin/settings_general.vim 
grep -r map *
grep -r incsearch *
cd .vim/bundle/settings/after/
cd plugin/
vim settings_general.vim settings_misc.vim 
l
vim plugin_settings.vim 
cd
cd projects/Blio/
grep -r '->write' *
vim lib/Blio.pm lib/Blio/*
cd ../blog_perl/master/
cd ../../Bl
cd ../../Blio/
grep -r -- '->write' *
grep -r -- '->run' *
vim lib/Blio.pm 
metacpan_namespace.pl --module Class::DBI --size 20
metacpan_namespace.pl DBIx::Closs --size=20
metacpan_namespace.pl --module DBIx::Class --size 20
vance
vance
vim .ssh/config
vance
vim .ssh/config
exit
cvs
cd projects/dot_vim/
git diff .vim/bundle/settings/after/plugin/plugin_settings.vim
cd .vim/bundle/settings/
mkdir ftplugin
cd ftplugin/
vim help.vim
gtl
vim .vimrc
gs
git diff .vimrc
vim .vim/bundle/settings/after/plugin/settings_general.vim 
grep -r map *
grep -r incsearch *
cd .vim/bundle/settings/after/
cd plugin/
vim settings_general.vim settings_misc.vim 
l
vim plugin_settings.vim 
cd
cd projects/Blio/
grep -r '->write' *
vim lib/Blio.pm lib/Blio/*
cd ../blog_perl/master/
cd ../../Bl
cd ../../Blio/
grep -r -- '->write' *
grep -r -- '->run' *
vim lib/Blio.pm 
grep -r -- '->process'
metacpan_namespace.pl --module Class::DBI --size 20
metacpan_namespace.pl DBIx::Closs --size=20
metacpan_namespace.pl --module DBIx::Class --size 20
vance
vance
vim .ssh/config
vance
vim .ssh/config
exit
cvs
cd projects/dot_vim/
git diff .vim/bundle/settings/after/plugin/plugin_settings.vim
cd .vim/bundle/settings/
mkdir ftplugin
cd ftplugin/
vim help.vim
gtl
vim .vimrc
gs
git diff .vimrc
vim .vim/bundle/settings/after/plugin/settings_general.vim 
grep -r map *
grep -r incsearch *
cd .vim/bundle/settings/after/
cd plugin/
vim settings_general.vim settings_misc.vim 
l
vim plugin_settings.vim 
cd
cd projects/Blio/
grep -r '->write' *
vim lib/Blio.pm lib/Blio/*
cd ../blog_perl/master/
cd ../../Bl
cd ../../Blio/
grep -r -- '->write' *
grep -r -- '->run' *
vim lib/Blio.pm 
grep -r -- '->process'
grep -r -- '->process' *
metacpan_namespace.pl --module Class::DBI --size 20
metacpan_namespace.pl DBIx::Closs --size=20
metacpan_namespace.pl --module DBIx::Class --size 20
vance
vance
vim .ssh/config
vance
vim .ssh/config
exit
cvs
cd projects/dot_vim/
git diff .vim/bundle/settings/after/plugin/plugin_settings.vim
cd .vim/bundle/settings/
mkdir ftplugin
cd ftplugin/
vim help.vim
gtl
vim .vimrc
gs
git diff .vimrc
vim .vim/bundle/settings/after/plugin/settings_general.vim 
grep -r map *
grep -r incsearch *
cd .vim/bundle/settings/after/
cd plugin/
vim settings_general.vim settings_misc.vim 
l
vim plugin_settings.vim 
cd
cd projects/Blio/
grep -r '->write' *
vim lib/Blio.pm lib/Blio/*
cd ../blog_perl/master/
cd ../../Bl
cd ../../Blio/
grep -r -- '->write' *
grep -r -- '->run' *
vim lib/Blio.pm 
grep -r -- '->process'
grep -r -- '->process' *
vim lib/Blio/Node.pm 
metacpan_namespace.pl --module Class::DBI --size 20
metacpan_namespace.pl DBIx::Closs --size=20
metacpan_namespace.pl --module DBIx::Class --size 20
vance
vance
vim .ssh/config
vance
vim .ssh/config
exit
cvs
cd projects/dot_vim/
git diff .vim/bundle/settings/after/plugin/plugin_settings.vim
cd .vim/bundle/settings/
mkdir ftplugin
cd ftplugin/
vim help.vim
gtl
vim .vimrc
gs
git diff .vimrc
vim .vim/bundle/settings/after/plugin/settings_general.vim 
grep -r map *
grep -r incsearch *
cd .vim/bundle/settings/after/
cd plugin/
vim settings_general.vim settings_misc.vim 
l
vim plugin_settings.vim 
cd
cd projects/Blio/
grep -r '->write' *
vim lib/Blio.pm lib/Blio/*
cd ../blog_perl/master/
cd ../../Bl
cd ../../Blio/
grep -r -- '->write' *
grep -r -- '->run' *
vim lib/Blio.pm 
grep -r -- '->process'
grep -r -- '->process' *
vim lib/Blio/Node.pm 
grep -r -- '->_write_page' *
metacpan_namespace.pl --module Class::DBI --limit 20
metacpan_namespace.pl --module Class::DBI --size 20
metacpan_namespace.pl DBIx::Closs --size=20
metacpan_namespace.pl --module DBIx::Class --size 20
vance
vance
vim .ssh/config
vance
vim .ssh/config
exit
cvs
cd projects/dot_vim/
git diff .vim/bundle/settings/after/plugin/plugin_settings.vim
cd .vim/bundle/settings/
mkdir ftplugin
cd ftplugin/
vim help.vim
gtl
vim .vimrc
gs
git diff .vimrc
vim .vim/bundle/settings/after/plugin/settings_general.vim 
grep -r map *
grep -r incsearch *
cd .vim/bundle/settings/after/
cd plugin/
vim settings_general.vim settings_misc.vim 
l
vim plugin_settings.vim 
cd
cd projects/Blio/
grep -r '->write' *
vim lib/Blio.pm lib/Blio/*
cd ../blog_perl/master/
cd ../../Bl
cd ../../Blio/
grep -r -- '->write' *
grep -r -- '->run' *
vim lib/Blio.pm 
grep -r -- '->process'
grep -r -- '->process' *
grep -r -- '->_write_page' *
vim lib/Blio/Node.pm 
metacpan_namespace.pl --module Class::DBI --limit 20
metacpan_namespace.pl --module Class::DBI --size 20
metacpan_namespace.pl DBIx::Closs --size=20
metacpan_namespace.pl --module DBIx::Class --size 20
vance
vance
vim .ssh/config
vance
vim .ssh/config
exit
cvs
cd projects/dot_vim/
git diff .vim/bundle/settings/after/plugin/plugin_settings.vim
cd .vim/bundle/settings/
mkdir ftplugin
cd ftplugin/
vim help.vim
gtl
vim .vimrc
gs
git diff .vimrc
vim .vim/bundle/settings/after/plugin/settings_general.vim 
grep -r map *
grep -r incsearch *
cd .vim/bundle/settings/after/
cd plugin/
vim settings_general.vim settings_misc.vim 
l
vim plugin_settings.vim 
cd
cd projects/Blio/
grep -r '->write' *
vim lib/Blio.pm lib/Blio/*
cd ../blog_perl/master/
cd ../../Bl
cd ../../Blio/
grep -r -- '->write' *
grep -r -- '->run' *
vim lib/Blio.pm 
grep -r -- '->process'
grep -r -- '->process' *
grep -r -- '->_write_page' *
vim lib/Blio/Node.pm 
sudo dzil install
metacpan_namespace.pl --module Class::DBI
metacpan_namespace.pl --module Class::DBI --limit 20
metacpan_namespace.pl --module Class::DBI --size 20
metacpan_namespace.pl DBIx::Closs --size=20
metacpan_namespace.pl --module DBIx::Class --size 20
vance
vance
vim .ssh/config
vance
vim .ssh/config
exit
cvs
cd projects/dot_vim/
git diff .vim/bundle/settings/after/plugin/plugin_settings.vim
cd .vim/bundle/settings/
mkdir ftplugin
cd ftplugin/
vim help.vim
gtl
vim .vimrc
gs
git diff .vimrc
vim .vim/bundle/settings/after/plugin/settings_general.vim 
grep -r map *
grep -r incsearch *
cd .vim/bundle/settings/after/
cd plugin/
vim settings_general.vim settings_misc.vim 
l
vim plugin_settings.vim 
cd
cd projects/Blio/
grep -r '->write' *
vim lib/Blio.pm lib/Blio/*
cd ../blog_perl/master/
cd ../../Bl
cd ../../Blio/
grep -r -- '->write' *
grep -r -- '->run' *
vim lib/Blio.pm 
grep -r -- '->process'
grep -r -- '->process' *
grep -r -- '->_write_page' *
sudo dzil install
vim lib/Blio/Node.pm 
metacpan_namespace.pl --module Class::DBI
metacpan_namespace.pl --module Class::DBI --limit 20
metacpan_namespace.pl --module Class::DBI --size 20
metacpan_namespace.pl DBIx::Closs --size=20
metacpan_namespace.pl --module DBIx::Class --size 20
vance
vance
vim .ssh/config
vance
vim .ssh/config
exit
cvs
cd projects/dot_vim/
git diff .vim/bundle/settings/after/plugin/plugin_settings.vim
cd .vim/bundle/settings/
mkdir ftplugin
cd ftplugin/
vim help.vim
gtl
vim .vimrc
gs
git diff .vimrc
vim .vim/bundle/settings/after/plugin/settings_general.vim 
grep -r map *
grep -r incsearch *
cd .vim/bundle/settings/after/
cd plugin/
vim settings_general.vim settings_misc.vim 
l
vim plugin_settings.vim 
cd
cd projects/Blio/
grep -r '->write' *
vim lib/Blio.pm lib/Blio/*
cd ../blog_perl/master/
cd ../../Bl
cd ../../Blio/
grep -r -- '->write' *
grep -r -- '->run' *
vim lib/Blio.pm 
grep -r -- '->process'
grep -r -- '->process' *
grep -r -- '->_write_page' *
sudo dzil install
vim lib/Blio/Node.pm 
;lsdkj
metacpan_namespace.pl --module Class
metacpan_namespace.pl --module Class::DBI
metacpan_namespace.pl --module Class::DBI --limit 20
metacpan_namespace.pl --module Class::DBI --size 20
metacpan_namespace.pl DBIx::Closs --size=20
metacpan_namespace.pl --module DBIx::Class --size 20
vance
vance
vim .ssh/config
vance
vim .ssh/config
exit
cvs
cd projects/dot_vim/
git diff .vim/bundle/settings/after/plugin/plugin_settings.vim
cd .vim/bundle/settings/
mkdir ftplugin
cd ftplugin/
vim help.vim
gtl
vim .vimrc
gs
git diff .vimrc
vim .vim/bundle/settings/after/plugin/settings_general.vim 
grep -r map *
grep -r incsearch *
cd .vim/bundle/settings/after/
cd plugin/
vim settings_general.vim settings_misc.vim 
l
vim plugin_settings.vim 
cd
cd projects/Blio/
grep -r '->write' *
vim lib/Blio.pm lib/Blio/*
cd ../blog_perl/master/
cd ../../Bl
cd ../../Blio/
grep -r -- '->write' *
grep -r -- '->run' *
vim lib/Blio.pm 
grep -r -- '->process'
grep -r -- '->process' *
grep -r -- '->_write_page' *
vim lib/Blio/Node.pm 
;lsdkj
sudo dzil install
exit
release
cdl Dropbox/.dropbox.cache/
rm -fr 2013-07-1*
l
gp
exit
release
cdl Dropbox/.dropbox.cache/
l
rm -fr 2013-07-1*
ssh cvs.vwh.net
ssh cvs.vwh.net
ssh ayoung@cvs.vwh.net
lt
vance
vance
exit
lt
exit
ssh cvs.vwh.net
ssh ayoung@cvs.vwh.net
exit
ssh root@208.55.160.69
ssh root@208.55.160.69
ssh root@208.55.160.46
ssh root@208.55.160.69
ssh root@208.55.160.46
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
facelift
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
ssh root@208.55.160.46
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
ssh root@208.55.160.46
ssh root@208.55.160.46
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
exit
ssh root@208.55.160.46
ssh root@208.55.160.46
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
ssh ayoung@cvs.vwh.net
exit
ssh root@208.55.160.46
ssh root@208.55.160.46
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
ssh cvs.vwh.net
ssh ayoung@cvs.vwh.net
exit
ssh root@208.55.160.46
ssh root@208.55.160.46
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
exit
ssh cvs.vwh.net
ssh ayoung@cvs.vwh.net
exit
ssh root@208.55.160.46
ssh root@208.55.160.46
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
vim .bash_prompt
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
vim .bash_prompt
gs
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
vim .bash_prompt
gs
git diff .bash_aliases
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
vim .bash_prompt
gs
git diff .bash_aliases
ga .bash_aliases 
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
vim .bash_prompt
gs
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
l
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
gp
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
gp
l
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
gp
l
l ~
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
gp
l
l ~
l ~/.bash*
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
gp
l
l ~
l ~/.bash*
cat ~/.bash_history 
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
gp
l
l ~
l ~/.bash*
cat ~/.bash_history 
mv ~/.bash_history . ; ln -s ~/projects/dotfiles/.bash_history ~
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
gp
l
l ~
cat ~/.bash_history 
mv ~/.bash_history . ; ln -s ~/projects/dotfiles/.bash_history ~
l ~/.bash*
ssh root@208.55.160.46
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
gp
l ~
cat ~/.bash_history 
mv ~/.bash_history . ; ln -s ~/projects/dotfiles/.bash_history ~
l ~/.bash*
l
ssh root@208.55.160.46
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
gs
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
gp
l ~
cat ~/.bash_history 
mv ~/.bash_history . ; ln -s ~/projects/dotfiles/.bash_history ~
l ~/.bash*
l
vim .bash_history 
ssh root@208.55.160.46
ssh root@208.55.160.46
ssh-keygen -f "/home/harleypig/.ssh/known_hosts" -R 208.55.160.46
ssh root@208.55.160.69
ssh root@hichew.harleydev.com
cd Dropbox/wallpaper_download/
wget http://www.heathermorton.ca/blog/wp-content/uploads/2010/04/MG_9927-Edit.jpg
cd
cd projects/dotfiles/
vim .bash_prompt
git diff .bash_aliases
ga .bash_aliases 
gc 'changed git commit -v alias to include -m for slightly more convenience'
git diff .bash_prompt
ga .bash_prompt
gc 'added force reread of history file for each prompt'
gp
l ~
cat ~/.bash_history 
mv ~/.bash_history . ; ln -s ~/projects/dotfiles/.bash_history ~
l ~/.bash*
l
vim .bash_history 
gs
