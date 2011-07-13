Dir[ARGV.join(" ") + '/*.AVI'].each do |movie|
  command = %{
    tell application "ffmpegX"
      activate
      set contents of the fifth text field of front window to "#{movie}"
      set contents of the second text field of front window to "#{movie.sub('AVI.ff.mov', 'mov').sub('AVI', 'mov')}"
      tell application "System Events"
        tell process "ffmpegX" to keystroke "\r"
      end tell
    end tell
  }.strip.split("\n").collect {|l| l.strip}.join('\' -e \'')
  `osascript -e '#{command}'`
end
