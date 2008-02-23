ENV["RAILS_ENV"] = "test"
require "spec"
require File.dirname(__FILE__) + "/growler.rb"

describe Growler do
  before do
    @g = Growler.new(:directory => "/Users/siannopollo/Developer/Projects/RoleModel/privia")
  end
  
  describe "super class", :shared => true do
    it "should be defined" do
      Growler.should be_a_kind_of(Class)
    end
    
    it "should receive updates and last_log" do
      growler = Growler.new(:updates => "updates", :last_log => "last log")
      growler.updates.should == "updates"
      growler.last_log.should == "last log"
    end
    
    it "should respond to revision, committer, priority, message, directory and growl!" do
      %w(revision committer priority message directory).collect {|m| m.to_sym}.each do |method|
        @g.should respond_to(method)
      end
    end
    
    it "should return a project and snippets to ignore" do
      @g.project.should == "privia"
      @g.ignore.should == "/Users/siannopollo/Developer/Projects/RoleModel/"
    end
  end
  
  describe SVN do
    before do
      @svn = SVN.new
    end
    
    it "should be a Growler" do
      SVN.new.should be_a_kind_of(Growler)
    end
    
    describe "with updates" do
      before do
        @svn.directory = "/Users/siannopollo/Developer/Projects/RoleModel/privia"
        @svn.updates = %{U  /Users/siannopollo/Developer/Projects/RoleModel/privia/foo.c\nU  /Users/siannopollo/Developer/Projects/RoleModel/privia/bar.c\nUpdated to revision 2121.\n}
        @svn.last_log = 
%{------------------------------------------------------------------------
r2121 | pnicholson | 2007-12-03 15:38:12 -0500 (Mon, 03 Dec 2007) | 1 line

new mirkwood
------------------------------------------------------------------------}
      end
      
      it "should return true for updates?" do
        @svn.updates?.should be_true
      end
      
      it "should return some formatted updates" do
        @svn.formatted_updates.should == %{U  privia/foo.c\nU  privia/bar.c\nUpdated to revision 2121.\n}
      end
      
      it "should return a committer" do
        @svn.committer.should == "pnicholson"
      end
      
      it "should return a revision number" do
        @svn.revision.should == "2121"
      end
      
      it "should return a commit message" do
        @svn.message.should == "new mirkwood"
      end
      
      it "should return a priority of 0" do
        @svn.priority.should == 0
      end
      
      it "should have a project" do
        @svn.project.should == "privia"
      end
      
      it "should return a priority of 1" do
        @svn.updates = %{U  foo.c\nU  bar.c\nM  db/migrate/001_initial_migration.rb\nUpdated to revision 2.\n}
        @svn.priority.should == 1
      end
      
      it "should growl! a string when passed false" do
        @svn.growl!(false).should be_a_kind_of(String)
        %w(committer priority message formatted_updates project).each do |method|
          @svn.growl!(false).should include(@svn.send(method.to_sym).to_s)
        end
      end
      
      it "should really growl" do
        lambda {@svn.growl!}.should_not raise_error
      end
    end
    
    describe "without updates" do
      before do
        @svn.updates = "At revision 690."
      end
      
      it "should return false for updates?" do
        @svn.updates?.should be_false
      end
      
      it "should return nil for growl!" do
        @svn.growl!.should be_nil
      end
    end
  end
  
  describe Git do
    before do
      @git = Git.new
    end
    
    it "should be a Growler" do
      @git.should be_a_kind_of(Growler)
    end
    
    describe "with updates" do
      before do
        @git.updates = updates
        @git.last_log = last_log
        @git.directory = "/Users/siannopollo/Developer/Projects/RoleModel/column_test2/"
      end
      
      it "should return true for updates?" do
        @git.updates?.should be_true
      end
      
      it "should return some formatted updates" do
        @git.formatted_updates.should == "A  file.rb"
        @git.last_log = (last_log << %{\n:000000 100644 0000000... e69de29... A  db/migrate/002_create_stuff.rb})
        @git.formatted_updates.should == "A  file.rb\nA  db/migrate/002_create_stuff.rb"
      end
      
      it "should return a committer" do
        @git.committer.should == "steve <siannopollo@macBook.local>"
      end
      
      it "should return a revision number" do
        @git.revision.should == "7c245f8b18e6f291becdd9576e7be2e812ee4cb8"
      end
      
      it "should return a commit message" do
        @git.message.should == "added file.rb\nand some other really\ngreat stuff"
      end
      
      it "should return a priority of 0" do
        @git.priority.should == 0
      end
      
      it "should return a priority of 1" do
        @git.last_log = (last_log << %{\n:000000 100644 0000000... e69de29... A  db/migrate/002_create_stuff.rb})
        @git.priority.should == 1
      end
      
      it "should have a project" do
        @git.project.should == "column_test2"
      end
      
      it "should growl! a string when passed false" do
        @git.growl!(false).should be_a_kind_of(String)
        %w(committer priority message formatted_updates project).each do |method|
          @git.growl!(false).should include(@git.send(method.to_sym).to_s)
        end
      end
      
      it "should really growl" do
        lambda {@git.growl!}.should_not raise_error
      end
    end
    
    describe "without updates" do
      before do
        @git.updates = "Already up-to-date"
      end
      
      it "should return false for updates?" do
        @git.updates?.should be_false
      end
      
      it "should return nil for growl!" do
        @git.growl!.should be_nil
      end
    end
    
    def updates
%{remote: Generating pack...
remote: Done counting 3 objects.
Result has 2 objects.
remote: Deltifying 2 objects...
remote:  100% (2/2) done
remote: Total 2 (delta 1), reused 0 (delta 0)
Unpacking 2 objects...
 100% (2/2) done
* refs/remotes/origin/master: fast forward to branch 'master' of /Users/siannopollo/Developer/Projects/RoleModel/column_test2/
  old..new: 85bab34..7c245f8
Updating 85bab34..7c245f8
Fast forward
 0 files changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 file.rb}
    end
    
    def last_log
%{commit 7c245f8b18e6f291becdd9576e7be2e812ee4cb8
Author: steve <siannopollo@macBook.local>
Date:   Thu Feb 7 13:52:51 2008 -0500

    added file.rb
    and some other really
    great stuff

:000000 100644 0000000... e69de29... A  file.rb}
    end
  end
end