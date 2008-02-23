class Growler
  %w(updates last_log revision committer priority message directory).each {|attribute| attr_accessor attribute}
  
  def initialize(options={})
    options.each {|k, v| self.send("#{k}=", v)}
  end
  
  def formatted_log
    last_log.split("\n")
  end
  
  def project
    File.basename(directory)
  end
  
  def ignore
    directory.gsub(project, "")
  end
  
  def priority
    updates.include?("db/migrate") || last_log.include?("db/migrate") ? 1 : 0
  end
  
  def growl!(system=true)
    if updates?
      command = %{osascript ~/bin/growl/growlnotify.scpt '#{project} Update - #{committer}' '#{message}\n\n#{formatted_updates}' '~/bin/growl/mph.png' #{priority}}
      system ? system(command) : command
    end
  end
end

class SVN < Growler
  def updates?
    !(updates =~ /At revision \d+/) || updates.split("\n").size > 1
  end
  
  def formatted_updates
    updates.gsub(ignore, "") if updates?
  end
  
  def committer
    formatted_log[1].split(" | ")[1]
  end
  
  def revision
    formatted_log[1].split(" | ").first.scan(/\d+/).first
  end
  
  def message
    formatted_log[3..-2].join("\n")
  end
end

class Git < Growler
  def updates?
    !(updates.nil? || updates.include?("Already up-to-date"))
  end
  
  def formatted_updates
    if updates?
      formatted_log.inject([]) do |output, line|
        if line =~ /^\:/
          output << line.gsub(/^\:.*?([A-Z]{1}.*?$)/) {$1}
        else
          output
        end
      end.join("\n")
    end
  end
  
  def committer
    formatted_log[1].gsub("Author: ", "")
  end
  
  def revision
    formatted_log[0].gsub("commit ", "")
  end
  
  def message
    formatted_log.inject([]) do |output, line|
      line =~ /^\s{4}.+/ ? (output << line.gsub(/\s{4}/, "")) : output
    end.join("\n")
  end
end