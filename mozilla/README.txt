
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
//
This file should have the following content:
//
  pref("general.config.obscure_value", 0);          // Do not obscure the content with ROT-13
  pref("general.config.filename", "firefox.cfg");   // /Applications/Non-Apple/Firefox.app/Contents/MacOS

The "firefox.cfg" is actually a "user.js" file, see below for some examples.
Note: values can be set with "defaultPref" or "lockPref"

http://kb.mozillazine.org/User.js_file
http://kb.mozillazine.org/About:config_entries
http://kb.mozillazine.org/Security_Policies
http://kb.mozillazine.org/Locking_preferences
https://developer.mozilla.org/en-US/docs/Automatic_Mozilla_Configurator/Locked_config_settings

