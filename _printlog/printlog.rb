require "date"
require "time"

class Printlog
  DEFAULTS = {:limit => 15, :developer => nil, :dates => nil, :format => "plain"}
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
  
  class Formatter
    attr_reader :printer
    def initialize(printer)
      @printer = printer
    end
    
    def formatted_log_entries
      dated_entries = printer.dates.nil? ? log_entries :
        log_entries.select {|entry| printer.start_date <= entry.date && entry.date <= printer.end_date}
      
      developer_entries = printer.developer.nil? ? log_entries :
        log_entries.select {|entry| entry.developer =~ /#{printer.developer}/}
      
      dated_entries & developer_entries
    end
    
    def report(format)
      if format == "plain"
        formatted_log_entries.collect {|entry| entry.report}.compact
      else
        invoice_report(formatted_log_entries)
      end
    end
    
    def invoice_report(entries)
      raise "To create an invoice, you must provide a developer" if printer.developer.nil?
      
      output, dates = "", entries.collect {|e| e.report.scan(/\[(.*?)\]/).last}.flatten.uniq
      dates.each do |date|
        output << "#{Time.parse(date).strftime("%m/%d/%Y")} - ?? hours\n"
        dated_entries = entries.select {|e| e.date.to_s == date}
        dated_entries.each do |entry|
          content = "  #{entry.report(false)}"
          output << (content =~ /\n$/ ? content : "#{content}\n")
        end
        output << "\n"
      end
      output
    end
  end
  
  class SVNFormatter < Formatter
    def log
      @log ||= `svn log #{printer.directory} --limit #{printer.limit}`
    end
    
    def separator
      @separator ||= log.scan(/^-.*?-$/).first
    end
    
    def log_entries
      @log_entries ||= log.split(separator)[1..-2].collect {|entry| SVNLogEntry.new(entry, printer)}
    end
  end
  
  class GITFormatter < Formatter
    def log
      @log ||= `cd #{printer.directory} && git log -n#{printer.limit} | cat`
    end
    
    def separator
      @separator ||= "?????"
    end
    
    def log_entries
      @log_entries ||= log.gsub(/^commit \w{40}/, separator).split(separator)[1..-1].collect {|entry| GITLogEntry.new(entry, printer)}
    end
  end
  
  class LogEntry
    attr_reader :developer, :message, :date, :printer
    def initialize(entry, printer)
      @printer = printer
    end
    
    def report(with_date=true)
      "* #{"#{developer} "if use_developer?}#{"[#{date.to_s}] - " if with_date}#{message}"
    end
    
    def use_developer?
      printer.developer.nil?
    end
  end
  
  class SVNLogEntry < LogEntry
    def initialize(entry, printer)
      super
      pieces = entry.split(" | ")
      @developer = pieces[1]
      @message = pieces.last.split("\n\n").last
      @date = Date.parse(pieces[2].gsub(/\(.*?\)/, ""))
    end
  end
  
  class GITLogEntry < LogEntry
    attr_reader :commit
    def initialize(entry, printer)
      super
      pieces = entry.split("\n")
      @commit = pieces.shift
      @developer = parse_developer(pieces)
      @date = Date.parse(pieces.shift.gsub("Date:   ", ""))
      @message = parse_message(pieces)
    end
    
    def parse_developer(pieces)
      if pieces.first !~ /Author\:/
        pieces.shift
      end
      pieces.shift.gsub("Author: ", "")
    end
    
    def parse_message(full_message)
      full_message.inject([]) do |output, line|
        line =~ /^\s{4}.+/ ? (output << line.gsub(/\s{4}/, "")) : output
      end.join("\n") + "\n"
    end
  end
end