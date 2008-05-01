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
        collector.join(" ").ljust(80) + "\n" # TODO: FIX THIS!!! It isn't doing anything
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
