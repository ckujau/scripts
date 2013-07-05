Mozilla default settings

== Per-user ==

Place a file called "user.js" into the profile directory:

  Linux: ~/.mozilla/firefox/NAME/
  MacOS: ~/Library/Application Support/Firefox/Profiles/NAME/
Windows: %APPDATA%\Mozilla\Firefox\Profiles\NAME\

Note: values are set with "user_pref"

== Per-site ==

Place a file called "local-settings.js" into the installation directory:

  Linux: /usr/lib/firefox/defaults/preferences/
  MacOS: /Applications/Firefox.app/Contents/MacOS/defaults/pref/
Windows: %ProgramFiles%\Mozilla Firefox\defaults\pref\

This file should have the following content:

  // Do not obscure the content with ROT-13
  pref("general.config.obscure_value", 0);
  pref("general.config.filename", "firefox.cfg");

The "firefox.cfg" must be stored where the actual Mozilla binary is located:

  Linux: /usr/lib/firefox/
  MacOS: /Applications/Firefox.app/Contents/MacOS/
Windows: %ProgramFiles%\Mozilla Firefox\

Note: values can be set with "defaultPref" or "lockPref"

== Links ==

http://kb.mozillazine.org/User.js_file
http://kb.mozillazine.org/About:config_entries
http://kb.mozillazine.org/Security_Policies
http://kb.mozillazine.org/Locking_preferences
