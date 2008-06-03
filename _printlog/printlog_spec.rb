require "spec"
require File.dirname(__FILE__) + "/printlog.rb"

describe Printlog do
  describe "svn" do
    before(:all) do
      @printer = Printlog.new("/Users/siannopollo/Developer/Projects/OpenSource/mail_fetcher", :limit => 6)
      @formatter = @printer.formatter
      @formatter.stub!(:log).and_return(svn_log)
    end
    
    it "should have some methods" do
      @printer.should respond_to(:directory)
      @printer.should respond_to(:limit)
      @printer.should respond_to(:developer)
      @printer.should respond_to(:scm)
      
      @formatter.should respond_to(:log)
      @formatter.should respond_to(:log_entries)
      @formatter.should respond_to(:report)
    end
    
    it "should determine scm type" do
      @printer.scm.should == "svn"
    end
    
    it "should have a separator extracted from the log" do
      @formatter.separator.should == "------------------------------------------------------------------------"
    end
    
    it "should have entries for the given log" do
      @formatter.formatted_log_entries.size.should == 6
      @formatter.formatted_log_entries.first.should be_a_kind_of(SVNLogEntry)
    end
    
    describe "entries" do
      before do
        @entry = @formatter.formatted_log_entries.first
      end
      
      it "should have a developer, message, and date" do
        @entry.developer.should == "siannopollo"
        @entry.message.should == "modified README\n"
        @entry.date.to_s.should == "2008-02-15"
      end
      
      it "should have a report" do
        @entry.report.should == "* siannopollo [2008-02-15] - modified README\n"
      end
    end
    
    describe "report" do
      it "should generate" do
        @printer.report.should include("* siannopollo [2008-02-15] - modified README\n")
        @printer.stub!(:developer).and_return("siannopollo")
        @printer.report.should include("* [2008-02-15] - modified README\n")
      end
      
      it "should be blank if the developer was not found in any of the log entries" do
        @printer.stub!(:developer).and_return("jown") # Juan Own :-)
        @printer.report.should be_empty
      end
    end
  end
  
  describe "git" do
    before(:all) do
      @printer = Printlog.new("/Users/siannopollo/Developer/Projects/PrepChamps/prepchamps", :limit => 6)
      @formatter = @printer.formatter
      @formatter.stub!(:log).and_return(git_log)
    end
    
    it "should determine scm type" do
      @printer.scm.should == "git"
    end
    
    it "should have a static separator" do
      @formatter.separator.should == "?????"
    end
    
    it "should have entries for the given log" do
      @formatter.formatted_log_entries.size.should == 6
      @formatter.formatted_log_entries.first.should be_a_kind_of(GITLogEntry)
    end
    
    describe "entries" do
      before do
        @entry = @formatter.formatted_log_entries.first
      end
      
      it "should have a developer, message, and date" do
        @entry.developer.should == "steve <siannopollo@macBook.local>"
        @entry.date.to_s.should == "2008-02-28"
        @entry.message.should == "Merge branch 'master' of git@192.168.50.17:prepchamps\nConflicts:\n	spec/models/user_spec.rb\n"
      end
      
      it "should have a report" do
        @entry.report.should == "* steve <siannopollo@macBook.local> [2008-02-28] - Merge branch 'master' of git@192.168.50.17:prepchamps\nConflicts:\n	spec/models/user_spec.rb\n"
      end
    end
    
    describe "report" do
      it "should generate" do
        @printer.report.should include("* steve <siannopollo@macBook.local> [2008-02-28] - Merge branch 'master' of git@192.168.50.17:prepchamps\nConflicts:\n	spec/models/user_spec.rb\n")
        @printer.stub!(:developer).and_return("steve")
        @printer.report.should include("* [2008-02-28] - Merge branch 'master' of git@192.168.50.17:prepchamps\nConflicts:\n	spec/models/user_spec.rb\n")
      end
      
      it "should be blank if the developer was not found in any of the log entries" do
        @printer.stub!(:developer).and_return("jown") # Juan Own :-)
        @printer.report.should be_empty
      end
    end
  end
  
  describe "date sorting" do
    before(:all) do
      @printer = Printlog.new("/Users/siannopollo/Developer/Projects/OpenSource/mail_fetcher", :limit => 6, :dates => "2/12/2008-2/14/2008")
      @formatter = @printer.formatter
    end
    
    it "should have a start date and end date" do
      @printer.start_date.to_s.should == "2008-02-12"
      @printer.end_date.to_s.should == "2008-02-14"
    end
    
    it "should only give back entries within a certain date range" do
      @formatter.stub!(:log).and_return(svn_log)
      @formatter.log_entries.size.should == 6
      @formatter.formatted_log_entries.size.should == 4
    end
  end
end

describe Printlog, "format" do
  before do
    @printer = Printlog.new("/Users/siannopollo/Developer/Projects/PrepChamps/prepchamps", :limit => 6, :developer => "steve", :dates => nil)
    @formatter = @printer.formatter
    @formatter.stub!(:log).and_return(git_log)
  end
  
  it "should default to plain" do
    @printer.format.should == "plain"
  end
  
  it "should do something different for an invoice format" do
    @printer.stub!(:format).and_return("invoice")
    @printer.report.should include("02/28/2008 - ?? hours")
  end
  
  it "should have a tabular invoice format" do
    @printer.stub!(:format).and_return("tabular_invoice")
    @printer.report.should == tabular_output
  end
end

describe Printlog, "extras" do
  before do
    @converter = Printlog::Converter.new(default_format_report)
  end
  
  it "should be able to convert default format to tabular invoice format" do
    @converter.report(:tabular_invoice).should == default_to_tabular_format
  end
  
  it "should be able to convert default format to regular invoice format" do
    @converter.report(:invoice).should == default_to_invoice_format
  end
end

def default_format_report
%{* adamw [2008-04-03] - Shaved a few seconds off test run by avoiding rendering of dashboard for every login
* adamw [2008-04-03] - Updated all plugins, fixed problem where config.gem with facets/htmlentities (only for tarantula, which runs forever) caused app to not run
* adamw [2008-04-03] - Pistonizing rspec
* adamw [2008-04-03] - Pistonizing rspec
* adamw [2008-04-02] - We had to unpack haml into our app for now since there was a change to how template handlers are registered with ActionView.
BUG: Inviting to hub should not re-invite to that hub, but it should still allow others to invite to their hub. Be careful, and pair with someone, cause there are probably issues with 'who from', too.
}
end

def default_to_tabular_format
%{    Date        Description                                                                      Time         Total
------------------------------------------------------------------------------------------------------------------------
| 2008-04-03 | Shaved a few seconds off test run by avoiding rendering of dashboard for       |           |            |
|            | every login                                                                    |           |            |
|            |--------------------------------------------------------------------------------|           |            |
|            | Updated all plugins, fixed problem where config.gem with facets/htmlentities   |           |            |
|            | (only for tarantula, which runs forever) caused app to not run                 |           |            |
|            |--------------------------------------------------------------------------------|           |            |
|            | Pistonizing rspec                                                              |           |            |
|            |--------------------------------------------------------------------------------|           |            |
|            | Pistonizing rspec                                                              |           |            |
------------------------------------------------------------------------------------------------------------------------
| 2008-04-02 | We had to unpack haml into our app for now since there was a change to how     |           |            |
|            | template handlers are registered with ActionView.                              |           |            |
|            | BUG: Inviting to hub should not re-invite to that hub, but it should still     |           |            |
|            | allow others to invite to their hub. Be careful, and pair with someone, cause  |           |            |
|            | there are probably issues with 'who from', too.                                |           |            |
------------------------------------------------------------------------------------------------------------------------
                                                                                     TOTALS:
}
end

def default_to_invoice_format
%{04/03/2008 - ?? hours
  * Shaved a few seconds off test run by avoiding rendering of dashboard for every login
  * Updated all plugins, fixed problem where config.gem with facets/htmlentities (only for tarantula, which runs forever) caused app to not run
  * Pistonizing rspec
  * Pistonizing rspec

04/02/2008 - ?? hours
  * We had to unpack haml into our app for now since there was a change to how template handlers are registered with ActionView.
BUG: Inviting to hub should not re-invite to that hub, but it should still allow others to invite to their hub. Be careful, and pair with someone, cause there are probably issues with 'who from', too.

Total hours worked: ?? hours
Pay Rate: ?? per hour

Total Due: ??

Thanks!

Steve Iannopollo
3121C Aileen Dr
Raleigh, NC 27606}
end

def svn_log
%{------------------------------------------------------------------------
r6 | siannopollo | 2008-02-15 19:37:07 -0500 (Fri, 15 Feb 2008) | 1 line

modified README
------------------------------------------------------------------------
r5 | siannopollo | 2008-02-15 19:34:44 -0500 (Fri, 15 Feb 2008) | 1 line

finally how i want it
------------------------------------------------------------------------
r4 | siannopollo | 2008-02-14 19:30:50 -0500 (Fri, 15 Feb 2008) | 1 line

getting rid of git
some extra interesting commit message that will take up a significantly large portion of text
------------------------------------------------------------------------
r3 | siannopollo | 2008-02-14 19:28:05 -0500 (Fri, 15 Feb 2008) | 1 line

ignoring stuff
------------------------------------------------------------------------
r2 | siannopollo | 2008-02-13 19:24:34 -0500 (Fri, 15 Feb 2008) | 2 lines

Initial import

------------------------------------------------------------------------
r1 | siannopollo | 2008-02-12 19:19:34 -0500 (Fri, 15 Feb 2008) | 1 line

setting up directories
------------------------------------------------------------------------
}
end

def git_log
%{commit 37b612ba40f60a73ad2d13784a114dd02fb3c27c
Merge: 2da5c16... 5dd6d74...
Author: steve <siannopollo@macBook.local>
Date:   Thu Feb 28 16:56:02 2008 -0500

    Merge branch 'master' of git@192.168.50.17:prepchamps

    Conflicts:

    	spec/models/user_spec.rb

commit 2da5c16ce79f59abeaa1899c0da1171ac0afee24
Author: steve <siannopollo@macBook.local>
Date:   Thu Feb 28 16:54:35 2008 -0500

    improved deploy script to be able to allow all developers to add their public keys to .ssh/authorized_keys so no passwords are needed when deploying

commit 5dd6d7420f0d825d81837c1692d180b57d513f1b
Author: Matthew Bass <matt@anacreon.local>
Date:   Thu Feb 28 16:23:01 2008 -0500

    Continued writing order unit tests

commit 98127d143e407b6a842e95a7c665637580b3b68b
Author: Matthew Bass <matt@anacreon.local>
Date:   Thu Feb 28 16:09:48 2008 -0500

    Wrote unit tests for Order model

commit 97177ae8624ca9e2f6c560132e4b8988b04e313d
Merge: 8804813... af2c7fd...
Author: Christopher Redinger <redinger@gmail.com>
Date:   Wed Feb 28 11:00:29 2008 -0500

    Merge commit 'braid/svn/vendor/plugins/rspec-on-rails' into braid/track

commit 3cdba16633e215a9e0226c7854ff193948dc9fa5
Merge: aa27f11... 739a12a...
Author: steve <siannopollo@macBook.local>
Date:   Thu Feb 28 15:09:05 2008 -0500

    Merge branch 'master' of git@192.168.50.17:prepchamps}
end

def tabular_output
%{    Date        Description                                                                      Time         Total
------------------------------------------------------------------------------------------------------------------------
| 2008-02-28 | Merge branch 'master' of git@192.168.50.17:prepchamps                          |           |            |
|            | Conflicts:                                                                     |           |            |
|            | spec/models/user_spec.rb                                                       |           |            |
|            |--------------------------------------------------------------------------------|           |            |
|            | improved deploy script to be able to allow all developers to add their public  |           |            |
|            | keys to .ssh/authorized_keys so no passwords are needed when deploying         |           |            |
|            |--------------------------------------------------------------------------------|           |            |
|            | Merge branch 'master' of git@192.168.50.17:prepchamps                          |           |            |
------------------------------------------------------------------------------------------------------------------------
                                                                                     TOTALS:
}
end

def rputs(*thing)
  puts *["<pre>", thing, "</pre>"].flatten
end