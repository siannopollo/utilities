on run argv
  set project to item 1 of argv
  
  tell application "Terminal"
    tell application "System Events"
      tell process "Terminal" to keystroke "t" using command down
    end tell
    do script "m" & project in first tab of front window
    do script "b" & project in second tab of front window
    do script "g" & project in second tab of front window
    tell first tab of front window to set selected to true
  end tell
end run