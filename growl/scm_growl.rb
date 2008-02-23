#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/growler.rb"

begin
  directory = ARGV.shift
  commands = ARGV.join(" ")
  
  loop do
    if eval(`test -e #{directory}/.svn && echo true`)
      updates, last_log = `svn up #{directory}`, `svn log #{directory} --limit 1`
      growler = SVN.new(:updates => updates, :last_log => last_log, :directory => directory)
    else
      updates, last_log = `cd #{directory} && git pull #{commands.empty? ? nil : commands}`, `cd #{directory} && git show --raw`
      growler = Git.new(:updates => updates, :last_log => last_log, :directory => directory)
    end
    
    growler.growl!
    sleep 180
  end
rescue
  `ps | egrep ruby.*?growl.rb | grep -v egrep |  cut -d" " -f2 | xargs kill -9`
  `~/bin/growl/scm_growl.rb #{directory}`
end