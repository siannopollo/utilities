require "date"
require "time"
require "ostruct"

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
  
  class Formatter
    attr_reader :printer
    def initialize(printer)
      @printer = printer
    end
    
    def formatted_log_entries
      dated_entries = printer.dates.nil? ? log_entries :
        log_entries.select {|entry| printer.start_date <= entry.date && entry.date <= printer.end_date}
      
      developer_entries = printer.developer.nil? ? log_entries :
        log_entries.select {|entry| entry.developer =~ %r{#{printer.developer}}}
      
      dated_entries & developer_entries
    end
    
    def report(format)
      if format == "plain"
        formatted_log_entries.collect {|entry| entry.report}.compact
      else
        raise "To create an invoice, you must provide a developer" if printer.developer.nil?
        instance_eval "#{format}_report(formatted_log_entries)"
      end
    end
    
    def invoice_report(entries)
      output = ""
      dates_for_entries(entries).each do |date|
        output << "#{Time.parse(date).strftime("%m/%d/%Y")} - ?? hours\n"
        dated_entries = entries.select {|e| e.date.to_s == date}
        dated_entries.each do |entry|
          content = "  #{entry.report(false)}"
          output << (content =~ /\n$/ ? content : "#{content}\n")
        end
        output << "\n"
      end
      output << %{Total hours worked: ?? hours\nPay Rate: ?? per hour\n\nTotal Due: ??\n\nThanks!\n\nSteve Iannopollo\n3121C Aileen Dr\nRaleigh, NC 27606}
      output
    end
    
    def tabular_invoice_report(entries)
      output, horizontal_separator  = "    Date        Description" + (" "*70) + "Time         Total\n", ("-" * 120) + "\n"
      output << horizontal_separator
      dates_for_entries(entries).each do |date|
        dated_entries = entries.select {|e| e.date.to_s == date}
        output <<  "| " + date.to_s + " |"
        dated_entries.each_with_index do |entry, i|
          date_place_holder, time, total = "|            |", "|           ", "|            |\n"
          formatted_message = format_message(entry.message, time, total)
          output << date_place_holder unless i == 0
          output << formatted_message
          if entry == dated_entries.last
            output << horizontal_separator
          else
            output << date_place_holder + ("-" * 80) + time + total
          end
        end
      end
      output << " "*85 + "TOTALS:\n"
      output
    end
    
    def format_message(message, time, total)
      pieces = message.split("\n")
      
      lines = pieces.collect do |old_line|
        words, new_lines = old_line.split, []
        while !words.empty?
          collector = [" "]
          while (collector.join(" ") + "#{words.first} ").length < 80 && !words.empty?
            collector << words.shift
          end
          collector.join(" ").ljust(80) + "\n"
          new_lines << collector
        end
        new_lines.flatten
      end
      
      lines = lines.join(" ").gsub("  ", "\n ").sub("\n ", " ").split("\n").collect {|l| l.sub("  ", " ").ljust(80)}
      first_line = lines.shift
      first_line << (time + total)
      return first_line if lines.size == 0
      
      date_place_holder = "|            |"
      new_lines = first_line + lines.collect do |line|
        date_place_holder + line + time + total
      end.join
      return new_lines
    end
    
    def dates_for_entries(entries)
      entries.collect {|e| e.report.scan(/\[(.*?)\]/).last}.flatten.uniq
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
      "* #{"#{developer} "if use_developer?}#{"[#{date.to_s}] - " if with_date}#{message}#{"\n" unless message =~ /\n$/}"
    end
    
    def use_developer?
      printer.developer.nil?
    end
    
    def ==(other)
      self.object_id == other.object_id
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
        line =~ /^\s{4}.+/ ? (output << line.gsub(/\s{4}/, "")) : (output << line)
        output
      end.join("\n").sub("\n", "").gsub("\n\n", "\n") + "\n"
    end
  end
  
  # Utility class to convert default format stuff into another format
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
