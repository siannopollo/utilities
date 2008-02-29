on run argv
  set project to item 1 of argv
  
  tell application "Terminal"
    tell application "System Events"
      tell process "Terminal" to keystroke "t" using command down
      tell process "Terminal" to keystroke "t" using command down
    end tell
    do script "s" & project in first tab of front window
    do script "m" & project in second tab of front window
    do script "g" & project in third tab of front window
    do script "localhost" in second tab of front window
    tell second tab of front window to set selected to true
  end tell
end run