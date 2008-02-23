on run argv
  set theDirectory to item 1 of argv
  
  tell application "TextMate"
    activate
    open theDirectory & ".tmproj"
    return "opened project"
  end tell
end run