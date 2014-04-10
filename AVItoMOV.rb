Dir[ARGV.join(" ") + '/*.AVI'].each do |movie|
  # We don't launch ffmpegX here because I want to be sure that the app is
  # already launched and the proper settings (aspect ratio mainly) have been set
  command = %{
    tell application "ffmpegX"
      activate
      set contents of the fifth text field of front window to "#{movie}"
      set contents of the second text field of front window to "#{movie.sub('AVI.ff', 'mov').sub('AVI', 'mov')}"
      tell application "System Events"
        tell process "ffmpegX" to keystroke "\r"
      end tell
    end tell
  }.strip.split("\n").collect {|l| l.strip}.join('\' -e \'')
  `osascript -e '#{command}'`
end
