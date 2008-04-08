on run argv
  set theProject to item 1 of argv
  set theDirectory to item 2 of argv
  
  tell application "TextMate"
    activate
    open theDirectory & "/" & theProject & ".tmproj"
    return "opened project"
  end tell
end run