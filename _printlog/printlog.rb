require "date"
class Printlog
  attr_reader :directory, :limit, :developer, :formatter, :report, :dates
  def initialize(directory, options={})
    @directory = directory.gsub("\n", "")
    parse_options(options)
    @formatter = eval("#{scm.upcase}Formatter.new(self)")
  end
  
  def parse_options(options)
    defaults.update(options).each {|k, v| instance_variable_set(:"@#{k}", v)}
  end
  
  def defaults
    {:limit => 15, :developer => nil, :dates => nil, :format => "plain"}
  end
  
  def scm
    @scm ||= `test -d #{directory}/.git && echo git || echo svn`.gsub("\n", "")
  end
  
  def report
    formatter.report
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
      if printer.dates.nil?
        log_entries
      else
        log_entries.select {|entry| printer.start_date <= entry.date && entry.date <= printer.end_date}
      end
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
    
    def report
      formatted_log_entries.collect do |entry|
        next unless entry.developer == printer.developer || printer.developer.nil?
        entry.report
      end.compact
    end
  end
  
  class GITFormatter < Formatter
    def log
      @log ||= `cd #{printer.directory} && git log -n#{printer.limit}`
    end
    
    def separator
      @separator ||= "commit "
    end
    
    def log_entries
      @log_entries ||= log.split(separator)[1..-1].collect {|entry| GITLogEntry.new(entry, printer)}
    end
    
    def report
      formatted_log_entries.collect do |entry|
        next unless entry.developer =~ /#{printer.developer}/ || printer.developer.nil?
        entry.report
      end.compact
    end
  end
  
  class LogEntry
    attr_reader :developer, :message, :date, :printer
    def initialize(entry, printer)
      @printer = printer
    end
    
    def report
      "* #{"#{developer} "if use_developer?}[#{date.to_s}] - #{message}"
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
      while pieces.first !~ /Author/
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