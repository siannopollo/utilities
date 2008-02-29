export PATH="~/bin:/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/var/db/dports/distfiles:/usr/local/mysql-standard-5.0.27-osx10.4-i686/bin:$PATH"
export EDITOR='mate -w'

for bigdir in $(ls ~/Developer/Projects/ | cut -d' ' -f7)
do 
  for dir in $(ls ~/Developer/Projects/$bigdir)
    do
      if [[ "$dir" =~ '.tmproj' ]]
      then
        continue
      fi
      
      alias cd$dir="cd ~/Developer/Projects/$bigdir/$dir"
      alias m$dir="cd$dir && test -e /Users/`whoami`/Developer/Projects/$bigdir/$dir.tmproj && pwd | xargs osascript ~/bin/mate_project.scpt || mate ."
      alias s$dir="cd$dir && ss"
      alias g$dir="~/bin/growl/scm_growl $dir"
      alias git$dir="~/bin/growl/scm_growl.rb /Users/`whoami`/Developer/Projects/$bigdir/$dir"
      alias o$dir="osascript ~/bin/open_project.scpt \"$dir\""
    done
done

alias localhost="open http://localhost:3000 -a 'Safari Webkit'"
alias flocalhost="open http://localhost:3000 -a Firefox"
alias slocalhost="open http://localhost:3000 -a Safari"
alias addall="svn st | grep ? | cut -d' ' -f7 | xargs svn add"
alias removeall="svn st | grep ? | cut -d' ' -f7 | xargs rm -Rf"
alias dbm="rake db:migrate && rake db:test:prepare"
alias dbfl="rake db:fixtures:load"
alias dbr="rake db:rebuild"
for var in "drop" "create"
do
  alias sql$var="mysqladmin -u root $var"
done

for var in "server" "generate" "console" "destroy" "plugin"
do
  alias s${var:0:1}="script/$var"
done

alias umember_hub="cdmember_hub && osascript update_project"