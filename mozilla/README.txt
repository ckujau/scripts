
 user.js
 The "user.js" file can be set on a per-user or per-site level.

== Per-user ==

  Linux: ~/.mozilla/firefox/NAME/user.js
  MacOS: ~/Library/Application Support/Firefox/Profiles/NAME/user.js
Windows: %APPDATA%\Mozilla\Firefox\Profiles\NAME\user.js

Note: values are set with "user_pref"

== Per-site ==

Place a file called "local-settings.js" into the installation directory:

  Linux: ?
  MacOS: /Applications/Firefox.app/Contents/MacOS/defaults/pref/
Windows: %ProgramFiles%\Mozilla Firefox\defaults\pref\

This file should have the following content:

  pref("general.config.obscure_value", 0);          // Do not obscure the content with ROT-13
  pref("general.config.filename", "firefox.cfg");

The filename must be location where the actual Mozilla binary is located:

   Linux: ?
   MacOS: /Applications/Firefox.app/Contents/MacOS
 Windows: %ProgramFiles%\Mozilla Firefox\

Note: values can be set with "defaultPref" or "lockPref"

== Links ==

http://kb.mozillazine.org/User.js_file
http://kb.mozillazine.org/About:config_entries
http://kb.mozillazine.org/Security_Policies
http://kb.mozillazine.org/Locking_preferences
