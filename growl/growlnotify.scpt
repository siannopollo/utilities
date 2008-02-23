-- growlNotify.applescript
-- Copyright (c) 2007 Silverchair Solutions. All rights reserved. http://www.silverchairsolutions.com

-- pass in like osascript growlNotify.applescript  
on run argv
  set mytitle to item 1 of argv
  set mymessage to item 2 of argv
  set myimage to item 3 of argv
  set mypriority to item 4 of argv
  
  tell application "GrowlHelperApp"
    set the allNotificationsList to ¬
      {"My Notification"}
    
    set the enabledNotificationsList to ¬
      {"My Notification"}
    
    register as application ¬
      "SCM Growler" all notifications allNotificationsList ¬
      default notifications enabledNotificationsList ¬
      icon of application "Script Editor"
    
    notify with name ¬
      "My Notification" title mytitle ¬
      description mymessage ¬
      application name ¬
      "SCM Growler" image from location myimage
    
  end tell
  
end run