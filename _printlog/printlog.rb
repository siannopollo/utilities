require "date"
require "time"
require "ostruct"
require File.dirname(__FILE__) + "/formatter"
require File.dirname(__FILE__) + "/log_entry"

class Printlog
  DEFAULTS = {:limit => 15, :developer => nil, :dates => nil, :format => "plain", :rate => 45}
  attr_reader :directory, :limit, :developer, :formatter, :report, :dates, :format
  
  def initialize(directory, options={})
    @directory = directory.gsub("\n", "")
    parse_options(options)
    @formatter = eval("#{scm.upcase}Formatter.new(self)")
  end
  
  def parse_options(options)
    DEFAULTS.update(options).each {|k, v| instance_variable_set(:"@#{k}", v)}
  end
  
  def scm
    @scm ||= `test -d #{directory}/.git && echo git || echo svn`.gsub("\n", "")
  end
  
  def report
    formatter.report(format)
  end
  
  def real_dates
    dates.nil? ? [] : dates.split("-").collect {|d| Date.parse(d)}
  end
  
  def start_date
    real_dates.empty? ? nil :
      (real_dates.first < real_dates.last ? real_dates.first : real_dates.last)
  end
  
  def end_date
    (real_dates - [start_date]).first
  end
  
  # Converts default format stuff into another format
  class Converter
    attr_reader :text, :entries
    def initialize(text)
      @text = text
      @entries = extract_entries!
    end
    
    def extract_entries!
      text.split("* ").collect do |entry|
        next if entry.empty?
        split_entry = entry.split(" - ")
        other_stuff = split_entry.shift
        message = split_entry.join
        developer = (other_stuff =~ /^\[/ ? nil : other_stuff.split(" ").first)
        date = other_stuff.sub(/.*?\[(.*?)\]/) {$1}
        build_entry(entry, message, developer, date)
      end.compact
    end
    
    def build_entry(entry, message, developer, date)
      built_entry = OpenStruct.new(:message => message, :developer => developer, :date => date)
      class << built_entry
        def report(with_date=true)
          %{* #{"[#{date.to_s}] - " if with_date}#{message}}
        end
        
        def ==(other)
          self.object_id == other.object_id
        end
      end
      built_entry
    end
    
    def report(format)
      formatter = Formatter.new(OpenStruct.new(:developer => nil))
      format ||= :tabular_invoice
      formatter.send :"#{format}_report", entries
    end
  end
end
