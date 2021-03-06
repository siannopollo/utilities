if [ -s ~/.rvm/scripts/rvm ] ; then source ~/.rvm/scripts/rvm ; fi
export PATH="~/bin:/usr/local/bin:/usr/local/libexec/git-core:/usr/local/sbin:/opt/local/bin:/opt/local/sbin:/opt/local/var/db/dports/distfiles:/usr/local/mysql/bin:/usr/local/texlive/2009/bin/universal-darwin:$PATH"
export EDITOR="mate -w"
export ARCHFLAGS="-arch x86_64"

complete -C "/opt/local/bin/gemedit --complete -e mate" gemedit

for bigdir in $(ls ~/Developer/Projects/ | cut -d' ' -f7)
do 
  if [[ "$bigdir" =~ '.zip' ]]
  then
    continue
  fi
  
  for dir in $(ls ~/Developer/Projects/$bigdir)
  do
    if [[ "$dir" =~ '.tmproj' ]]
    then
      continue
    fi
    
    # Allows for placement of .sh files in directories where projects live so that
    # we can strategically modify our aliases. If these are named the same as the
    # project for which are trying to replace aliases, we can overwrite the other
    # aliases since this gets run after the normal aliases for that project.
    if [[ "$dir" =~ '.sh' ]]
    then
      cd "/Users/siannopollo/Developer/Projects/$bigdir"
      . "$dir"
      cd
      continue
    fi
    
    alias cd$dir="cd ~/Developer/Projects/$bigdir/$dir"
    alias m$dir="cd$dir && test -e $dir.tmproj && open $dir.tmproj || (test -e $dir.xcodeproj && open $dir.xcodeproj || mate .)"
    alias s$dir="cd$dir && ss"
    alias g$dir="open -a Tick.app && cd$dir"
    alias git$dir="~/bin/growl/scm_growl.rb /Users/`whoami`/Developer/Projects/$bigdir/$dir"
    alias b$dir="open http://$dir.local -a Safari"
    alias o$dir="osascript ~/bin/open_project.scpt \"$dir\""
    alias l$dir="cd$dir && for f in log/*.log; do echo '' > \$f; done"
  done
done

alias localhost="open http://localhost:3000 -a Safari"
alias flocalhost="open http://localhost:3000 -a Firefox"
alias addall="test -e .svn && (svn st | grep ? | cut -d' ' -f7 | xargs svn add) || (test -d .git && git add -A . || (currentdir=$PWD && cd .. && git add -A . && cd $currentdir))"
alias removeall="test -e .svn && (svn st | grep ? | cut -d' ' -f7 | xargs rm -Rf) || (git status | grep deleted: | cut -d' ' -f 5 | xargs git rm)"
alias dbm="rake db:migrate db:test:clone"
alias dbfl="rake db:fixtures:load"
alias dbr="rake db:rebuild"
for var in "drop" "create"
do
  alias sql${var}db="mysqladmin -u root $var"
done

alias ss="test -d ./script && script/server || serve"
for var in "generate" "console" "destroy" "plugin"
do
  alias s${var:0:1}="script/$var"
done

if [[ -s "$HOME/.rvm/scripts/rvm" ]]  ; then source "$HOME/.rvm/scripts/rvm" ; fi

alias pandora="pianobar"
alias pow-me="powpath=\$PWD;cd ~/.pow;ln -s \$powpath;cd \$powpath;unset powpath"
### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi