ENV["RAILS_ENV"] = "test"
require "spec"
require File.dirname(__FILE__) + "/printlog.rb"

describe Printlog do
  before do
    @printer = Printlog.new("/Users/siannopollo/Developer/Projects/OpenSource/mail_fetcher")
  end
  
  it "should collect svn log entries and spit them out in a nice format" do
    @printer.should respond_to(:directory)
    @printer.should respond_to(:log)
    @printer.should respond_to(:separator)
    @printer.should respond_to(:log_entries)
    @printer.should respond_to(:report)
  end
  
  it "should generate a real report" do
    @printer.report.should include("* siannopollo [2008-02-15] - setting up directories\n")
  end
  
  describe "log" do
    before do
      @printer.stub!(:log).and_return(log)
    end
    
    it "should have a separator extracted from the log" do
      @printer.separator.should == "------------------------------------------------------------------------"
    end
    
    it "should have entries for the given log" do
      @printer.log_entries.size.should > 1
      @printer.log_entries.first.should be_a_kind_of(Printlog::LogEntry)
    end
    
    describe "entries" do
      before do
        @entry = @printer.log_entries.first
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
    
    describe "format" do
      it "should sort by dates" do
        pending "Allow the printer to take a date range and give the logs in that date range"
      end
    end
  end
  
  def log
%{------------------------------------------------------------------------
r6 | siannopollo | 2008-02-15 19:37:07 -0500 (Fri, 15 Feb 2008) | 1 line

modified README
------------------------------------------------------------------------
r5 | siannopollo | 2008-02-15 19:34:44 -0500 (Fri, 15 Feb 2008) | 1 line

finally how i want it
------------------------------------------------------------------------
r4 | siannopollo | 2008-02-15 19:30:50 -0500 (Fri, 15 Feb 2008) | 1 line

getting rid of git
------------------------------------------------------------------------
r3 | siannopollo | 2008-02-15 19:28:05 -0500 (Fri, 15 Feb 2008) | 1 line

ignoring stuff
------------------------------------------------------------------------
r2 | siannopollo | 2008-02-15 19:24:34 -0500 (Fri, 15 Feb 2008) | 2 lines

Initial import

------------------------------------------------------------------------
r1 | siannopollo | 2008-02-15 19:19:34 -0500 (Fri, 15 Feb 2008) | 1 line

setting up directories
------------------------------------------------------------------------}
  end
end