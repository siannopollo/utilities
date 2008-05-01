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
