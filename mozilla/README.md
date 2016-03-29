# Mozilla default settings
## Per-user

Place a file called `user.js` into the [profile directory](http://kb.mozillazine.org/Profile_folder):

```
  Linux: ~/.mozilla/firefox/NAME/
  MacOS: ~/Library/Application Support/Firefox/Profiles/NAME/
Windows: %APPDATA%\Mozilla\Firefox\Profiles\NAME\
```

Note: values are set with `user_pref`

## Per-site

Place a file called `autoconfig.js` into the [installation directory](http://kb.mozillazine.org/Installation_directory):

```
 Linux: /usr/lib{,64}/firefox/browser/defaults/preferences/
 MacOS: /Applications/Firefox.app/Contents/Resources/defaults/    => Firefox 34+
        /Applications/Firefox.app/Contents/MacOS/defaults/pref/   => until Firefox 33.x
Windows: %ProgramFiles%\Mozilla Firefox\defaults\pref\
```

This file should have the following content:

```
  // Do not obscure the content with ROT-13
  pref("general.config.obscure_value", 0);
  pref("general.config.filename", "mozilla.cfg");
```

The `mozilla.cfg` must be stored where the actual Mozilla binary is located:

```
  Linux: /usr/lib{,64}/firefox/
  MacOS: /Applications/Firefox.app/Contents/MacOS/
Windows: %ProgramFiles%\Mozilla Firefox\
```

Notes:
* Values in `mozilla.cfg` can be set with `defaultPref` or `lockPref`
* In Debian, Firefox is called Iceweasel and its defaults are stored
  elsewhere: both `autoconfig.js` and `mozilla.cfg` can reside in 
  `/etc/iceweasel/pref`, but the latter needs to be symlinked to `/usr/lib/iceweasel`

# Links
- http://kb.mozillazine.org/User.js_file
- http://kb.mozillazine.org/Prefs.js_file
- http://kb.mozillazine.org/About:config_entries
- http://kb.mozillazine.org/Locking_preferences
- http://kb.mozillazine.org/Security_Policies
