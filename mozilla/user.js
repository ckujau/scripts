//
// user.js
// The "user.js" file can be set on a per-user or per-site level.
//

// http://kb.mozillazine.org/App.update.auto
//  true - Download and install updates automatically (default)
// false - Ask the user what he wants to do when an update is available 
lockPref("app.update.auto", false);

// http://kb.mozillazine.org/Browser.cache.disk.enable
//  true - Store cache on the hard drive (default)
// false - Don't store cache on the hard drive
lockPref("browser.cache.disk.enable", false);

// http://kb.mozillazine.org/Browser.cache.disk.capacity
// Note: browser.cache.disk.enable must be set to "true"
// Amount of disk space allowed for the browser's cache (in KB, default: 50000)
lockPref("browser.cache.disk.capacity", 0);
lockPref("browser.cache.disk.smart_size.enabled", false);

// http://kb.mozillazine.org/Browser.cache.disk_cache_ssl
// Note: browser.cache.disk.enable must be set to "true"
//  true - Cache to disk content retrieved by SSL (default)
// false - Don't cache to disk content retrieved by SSL
// pref("browser.cache.disk_cache_ssl", false);

// http://kb.mozillazine.org/Browser.cache.check_doc_frequency
// Note: browser.cache.disk.enable or browser.cache.memory.enable must be set to "true"
// 0 - Check for a new version of a page once per session
// 1 - Check for a new version every time a page is loaded
// 2 - Never check for a new version
// 3 - Check for a new version when the page is out of date (default)
lockPref("browser.cache.check_doc_frequency", 1);

// http://kb.mozillazine.org/Unable_to_save_or_download_files
//  true - Use browser.download.downloadDir (default)
// false - Do not use browser.download.downloadDir
lockPref("browser.download.useDownloadDir", false);

// http://kb.mozillazine.org/Browser.safebrowsing.enabled
//  true - Compare visited URLs against a blacklist or submit URLs to a third party
//         to determine whether a site is legitimate (default)
// false - Disable Safe Browsing
lockPref("browser.safebrowsing.enabled", false);

// http://kb.mozillazine.org/Browser.safebrowsing.malware.enabled
//  true - Download data about malware and use it to screen downloads (default)
// false - Do not download malware blacklists and do not check downloads
lockPref("browser.safebrowsing.malware.enabled", false);

// http://kb.mozillazine.org/Browser.startup.homepage
lockPref("browser.startup.homepage", "about:");

// http://kb.mozillazine.org/Browser.startup.page
// 0 - Start with about:blank
// 1 - Start with browser.startup.homepage (default)
// 2 - Load the last visited page
// 3 - Resume the previous browser session
lockPref("browser.startup.page", 3);

// When changing "browser.newtab.url" is there any way to prevent the
// address bar from getting focus?
// https://support.mozilla.org/en-US/questions/929071
lockPref("browser.newtab.url", "about:blank");

// https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/Preference_reference/browser.pagethumbnails.capturing_disabled
//  true - The application doesn't create screenshots of visited web pages
// false - The application creates screenshots of visited web pages (default)
lockPref("browser.pagethumbnails.capturing_disabled", true);

// Find and manage downloaded files
// https://support.mozilla.org/en-US/kb/find-and-manage-downloaded-files
//  true - Use old download manager
// false - Use new download manger (default)
lockPref("browser.download.useToolkitUI", true); 

// http://kb.mozillazine.org/Browser.underline_anchors
//  true - Links are underlined by default (default)
// false - Links are not underlined by default
lockPref("browser.underline_anchors", false);

// http://kb.mozillazine.org/Layout.spellcheckDefault
// 0 - Disable spellchecker
// 1 - Enable spellchecker for multi-line controls (default)
// 2 - Enable spellchecker for multi-line controls and single-line controls
lockPref("layout.spellcheckDefault", 0);

// http://kb.mozillazine.org/Network.cookie.cookieBehavior
// 0 - All cookies are allowed (default)
// 1 - Only cookies from the originating server are allowed
// 2 - No cookies are allowed
// 3 - Third-party cookies are allowed only if that site has stored cookies
//     already from a previous visit 
lockPref("network.cookie.cookieBehavior", 1);

// http://kb.mozillazine.org/Network.cookie.lifetimePolicy
// 0 - The cookie's lifetime is supplied by the server (default)
// 1 - The user is prompted for the cookie's lifetime
// 2 - The cookie expires at the end of the session (when the browser closes)
// 3 - The cookie lasts for the number of days specified by network.cookie.lifetime.days
lockPref("network.cookie.lifetimePolicy", 3);

// http://kb.mozillazine.org/Network.cookie.lifetime.days
// Number of days to keep cookies (default: 90)
lockPref("network.cookie.lifetime.days", 1);

// https://support.mozilla.org/en-US/questions/873346
// Cookies Site Exceptions List has Disappeared since FF 6+
// pref("pref.privacy.disable_button.view_cookies", false);

// Clear on shutdown
lockPref("privacy.sanitize.sanitizeOnShutdown", true);
lockPref("privacy.clearOnShutdown.cache", true);
lockPref("privacy.clearOnShutdown.cookies", true);
lockPref("privacy.clearOnShutdown.offlineApps", true);
lockPref("privacy.clearOnShutdown.sessions", true);
lockPref("privacy.clearOnShutdown.downloads", false);
lockPref("privacy.clearOnShutdown.formdata", false);
lockPref("privacy.clearOnShutdown.history", false);

// http://kb.mozillazine.org/Privacy.donottrackheader.enabled
//  true - Send information about the user's tracking preferences to all websites. 
//         Prior to Firefox 21.0 and SeaMonkey 2.18, this is always "Do Not Track";
//         in Firefox 21.0 and later as well as SeaMonkey 2.18 and later, the header
//         sent depends on the privacy.donottrackheader.value setting
// false - Do not send any tracking preferences to any website (default)
lockPref("privacy.donottrackheader.enabled", true);

// http://kb.mozillazine.org/Privacy.donottrackheader.value
// Note: privacy.donottrackheader.enabled must be set to "true"
// 0 - A header stating consent to being tracked is sent to all websites
// 1 - A header stating the request not to be tracked is sent to all websites
lockPref("privacy.donottrackheader.value", 1);

// http://kb.mozillazine.org/Network.http.sendRefererHeader
// 0 - Never send the Referer header or set document.referrer
// 1 - Send the Referer header when clicking on a link, and set document.referrer for the following page
// 2 - Send the Referer header when clicking on a link or loading an image, and set document.referrer for the following page
lockPref("network.http.sendRefererHeader", 0);

// http://kb.mozillazine.org/Network.http.sendSecureXSiteReferrer
// Note: network.http.sendRefererHeader must be set to 1 or 2
//  true - Send the Referer header when navigating from a https site to another https site
// false - Don't send the Referer header when navigating from a https site to another https site
lockPref("network.http.sendSecureXSiteReferrer", false);

// Disable Location-Aware Browsing
// https://www.mozilla.org/en-US/firefox/geolocation/
lockPref("geo.enabled", false);

// Privacy-related changes coming to CSS :visited
// https://hacks.mozilla.org/2010/03/privacy-related-changes-coming-to-css-vistited/
lockPref("layout.css.visited_links_enabled", false);

// http://kb.mozillazine.org/Network.security.ports.banned
// A comma delimited list of port numbers to additionally block
// pref("network.security.ports.banned", "21,80");

// http://kb.mozillazine.org/Network.security.ports.banned.override
// A comma delimited list of port numbers to allow
// pref("network.security.ports.banned.override", "8080,8443");

//  true - Hide certain parts of the url
// false - All parts of the url are shown
lockPref("browser.urlbar.trimURLs", false);

//  true - The domain name including the top level domain is highlighted in the address
//         bar by coloring it black and the other parts grey.
// false - All parts of the url are given the same color: black
lockPref("browser.urlbar.formatting.enabled", false);

// How do I go Back/Forward and Pinch to zoom in Firefox using my MacBook Pro?
// https://support.mozilla.org/en-US/questions/903953
// pref("browser.gesture.swipe.down", NULL);
// pref("browser.gesture.swipe.left", NULL);
// pref("browser.gesture.swipe.right", NULL);
// pref("browser.gesture.swipe.up", NULL);

// Gecko user agent string reference
// https://developer.mozilla.org/en-US/docs/Gecko_user_agent_string_reference
// ORIG: pref("general.useragent.override", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:20.0) Gecko/20100101 Firefox/20.0");
// ALT1: pref("general.useragent.override", "Mozilla/5.0 (X11; Linux x86_64; rv:20.0) Gecko/20100101 Firefox/20.0");
lockPref("general.useragent.override", "Mozilla/5.0 (X11; Linux x86_64; rv:20.0) Gecko/20.0 Firefox/20.0");

// http://kb.mozillazine.org/Browser.tabs.closeButtons
// 0 - Display a close button on the active tab only 
// 1 - Display close buttons on all tabs
// 2 - Don’t display any close buttons
// 3 - Display a single close button at the end of the tab strip
lockPref("browser.tabs.closeButtons", 3);

// browser.tabs.insertRelatedAfterCurrent ==> changing the boolean, nothing happens, why?
// https://support.mozilla.org/en-US/questions/808388
lockPref("browser.tabs.insertRelatedAfterCurrent", false);

// http://kb.mozillazine.org/Browser.link.open_newwindow
// 1 - Open links, that would normally open in a new window, in the current tab/window
// 2 - Open links, that would normally open in a new window, in a new window
// 3 - Open links, that would normally open in a new window, in a new tab in the current window
// pref("browser.link.open_newwindow", 3);

// http://kb.mozillazine.org/Browser.link.open_newwindow.restriction
// 0 - Divert all links according to browser.link.open_newwindow
// 1 - Do not divert any links (browser.link.open_newwindow will have no effect)
// 2 - Divert all links according to browser.link.open_newwindow, unless the new
//     window specifies how it should be displayed. 
// pref("browser.link.open_newwindow.restriction", 0);

// http://kb.mozillazine.org/Layout.word_select.stop_at_punctuation
//  true - "Word" selection includes surrounding punctuation and only stops at whitespace, so
//         that for example double-clicking example.com/the/path and the other above-mentioned
//         shortcuts select the entire URL
// false - Word selection using the above mentioned shortcuts ends at punctuation characters
// pref("layout.word_select.stop_at_punctuation", false);

// http://kb.mozillazine.org/Issues_related_to_plugins
lockPref("plugins.click_to_play", true);

// http://kb.mozillazine.org/Keyword.enabled
//  true - If Mozilla cannot determine a URL from information entered in the Location Bar,
//         append the information to the URL in keyword.URL and redirect the user there
// false - Display an error message indicating the entered information is not a valid URL
lockPref("keyword.enabled", false);

// https://hg.mozilla.org/mozilla-central/file/tip/services/datareporting
lockPref("datareporting.policy.dataSubmissionEnabled", false);
lockPref("datareporting.policy.dataSubmissionPolicyAccepted", false);
lockPref("datareporting.policy.dataSubmissionPolicyBypassAcceptance", false);

// http://kb.mozillazine.org/Network.proxy.type
// 0 - Direct connection, no proxy
// 1 - Manual proxy configuration
// 2 - Proxy auto-configuration (PAC)
// 4 - Auto-detect proxy settings
// 5 - Use system proxy settings
defaultPref("network.proxy.type", 1);

// http://kb.mozillazine.org/Network.proxy.autoconfig_url
// When using local PAC files:
//   Linux: file:///home/NAME/.proxy.pac
//   MacOS: file:///Users/NAME/.proxy.pac
// Windows: file:///C:/Documents%20and%20Settings/NAME/proxy.pac
defaultPref("network.proxy.autoconfig_url", "http://proxy.example.org/proxy.pac");

// http://kb.mozillazine.org/Network.proxy.(protocol)
// http://kb.mozillazine.org/Network.proxy.(protocol)_port
defaultPref("network.proxy.http", "10.0.0.1");
defaultPref("network.proxy.http_port", 8080);
defaultPref("network.proxy.ssl", "10.0.0.1");
defaultPref("network.proxy.ssl_port", 8080);
defaultPref("network.proxy.ftp", "10.0.0.1");
defaultPref("network.proxy.ftp_port", 8080);
defaultPref("network.proxy.socks", "10.0.0.1");
defaultPref("network.proxy.socks_port", 8080);

// http://kb.mozillazine.org/Network.proxy.share_proxy_settings
//  true - Save the HTTP proxy as the proxy for the other protocols
// false - Save the proxy protocol settings separately
defaultPref("network.proxy.share_proxy_settings", true);

// http://kb.mozillazine.org/Network.proxy.no_proxies_on
defaultPref("network.proxy.no_proxies_on", "localhost, 127.0.0.1");

// http://kb.mozillazine.org/Network.proxy.socks_version
defaultPref("network.proxy.socks_version", 5);

// http://kb.mozillazine.org/Network.proxy.socks_remote_dns
//  true - Have the (SOCKS v5) proxy server perform DNS lookups
// false - Perform DNS lookups on the client
lockPref("network.proxy.socks_remote_dns", true);

// END
