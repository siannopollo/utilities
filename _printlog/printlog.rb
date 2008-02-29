require "date"
class Printlog
  attr_reader :directory, :limit, :developer
  
  def initialize(directory, limit=15, developer=nil)
    @directory, @limit, @developer = directory, limit, developer
  end
  
  def log
    @log ||= `svn log #{directory.gsub("\n", "")} --limit #{limit}`
  end
  
  def separator
    @separator ||= log.scan(/^-.*?-$/).first
  end
  
  def log_entries
    @log_entries ||= log.split(separator)[1..-2].collect {|entry| LogEntry.new(entry, self)}
  end
  
  def report
    log_entries.collect do |entry|
      next unless entry.developer == developer || developer.nil?
      entry.report
    end.compact
  end
  
  class LogEntry
    attr_reader :developer, :message, :date, :printer
    def initialize(entry, printer)
      @printer = printer
      
      pieces = entry.split(" | ")
      @developer = pieces[1]
      @message = pieces.last.split("\n\n").last
      @date = Date.parse(pieces[2].gsub(/\(.*?\)/, ""))
    end
    
    def report
      "* #{"#{developer} "if use_developer?}[#{date.to_s}] - #{message}"
    end
    
    def use_developer?
      printer.developer.nil?
    end
  end
end