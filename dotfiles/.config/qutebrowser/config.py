# Autogenerated config.py
#
# NOTE: config.py is intended for advanced users who are comfortable
# with manually migrating the config file on qutebrowser upgrades. If
# you prefer, you can also configure qutebrowser using the
# :set/:bind/:config-* commands without having to write a config.py
# file.
#
# Documentation:
#   qute://help/configuring.html
#   qute://help/settings.html

# Change the argument to True to still load settings configured via autoconfig.yml
config.load_autoconfig(False)

# Which cookies to accept. With QtWebEngine, this setting also controls
# other features with tracking capabilities similar to those of cookies;
# including IndexedDB, DOM storage, filesystem API, service workers, and
# AppCache. Note that with QtWebKit, only `all` and `never` are
# supported as per-domain values. Setting `no-3rdparty` or `no-
# unknown-3rdparty` per-domain on QtWebKit will have the same effect as
# `all`. If this setting is used with URL patterns, the pattern gets
# applied to the origin/first party URL of the page making the request,
# not the request URL. With QtWebEngine 5.15.0+, paths will be stripped
# from URLs, so URL patterns using paths will not match. With
# QtWebEngine 5.15.2+, subdomains are additionally stripped as well, so
# you will typically need to set this setting for `example.com` when the
# cookie is set on `somesubdomain.example.com` for it to work properly.
# To debug issues with this setting, start qutebrowser with `--debug
# --logfilter network --debug-flag log-cookies` which will show all
# cookies being set.
# Type: String
# Valid values:
#   - all: Accept all cookies.
#   - no-3rdparty: Accept cookies from the same origin only. This is known to break some sites, such as GMail.
#   - no-unknown-3rdparty: Accept cookies from the same origin only, unless a cookie is already set for the domain. On QtWebEngine, this is the same as no-3rdparty.
#   - never: Don't accept cookies at all.
config.set('content.cookies.accept', 'no-3rdparty', 'chrome-devtools://*')
config.set('content.cookies.accept', 'no-3rdparty', 'devtools://*')

# Value to send in the `Accept-Language` header. Note that the value
# read from JavaScript is always the global value.
# Type: String
config.set('content.headers.accept_language', 'en-US,en;q=0.5', 'https://matchmaker.krunker.io/*')

# User agent to send.  The following placeholders are defined:  *
# `{os_info}`: Something like "X11; Linux x86_64". * `{webkit_version}`:
# The underlying WebKit version (set to a fixed value   with
# QtWebEngine). * `{qt_key}`: "Qt" for QtWebKit, "QtWebEngine" for
# QtWebEngine. * `{qt_version}`: The underlying Qt version. *
# `{upstream_browser_key}`: "Version" for QtWebKit, "Chrome" for
# QtWebEngine. * `{upstream_browser_version}`: The corresponding
# Safari/Chrome version. * `{qutebrowser_version}`: The currently
# running qutebrowser version.  The default value is equal to the
# unchanged user agent of QtWebKit/QtWebEngine.  Note that the value
# read from JavaScript is always the global value. With QtWebEngine
# between 5.12 and 5.14 (inclusive), changing the value exposed to
# JavaScript requires a restart.
# Type: FormatString
config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} (KHTML, like Gecko) {upstream_browser_key}/{upstream_browser_version} Safari/{webkit_version}', 'https://web.whatsapp.com/')
config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}; rv:90.0) Gecko/20100101 Firefox/90.0', 'https://accounts.google.com/*')
config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99 Safari/537.36', 'https://*.slack.com/*')

# Load images automatically in web pages.
# Type: Bool
config.set('content.images', True, 'chrome-devtools://*')
config.set('content.images', True, 'devtools://*')

# Enable JavaScript.
# Type: Bool
config.set('content.javascript.enabled', True, 'chrome-devtools://*')
config.set('content.javascript.enabled', True, 'devtools://*')
config.set('content.javascript.enabled', True, 'chrome://*/*')
config.set('content.javascript.enabled', True, 'qute://*/*')

c.auto_save.session = True

# Autoplay
c.content.autoplay = True
autoplay_domains = ["youtube.com", "piped.kavin.rocks"]
try:
   with open(config.configdir / "secret_autoplay_false", "r") as saf:
      autoplay_domains += [l.strip() for l in saf if l.strip()]
except FileNotFoundError:
   pass
for dom in autoplay_domains:
   with config.pattern('*://*.'+dom+'/*') as p:
      p.content.autoplay = False

# Minimizing fingerprinting and annoying things
u_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36"

c.content.headers.do_not_track = True
c.content.canvas_reading = False
c.content.site_specific_quirks.enabled = False
c.content.geolocation = False
c.content.headers.user_agent = u_agent
c.content.media.audio_video_capture = False
c.content.media.audio_capture = False
c.content.media.video_capture = False
c.content.notifications.enabled = False
c.content.pdfjs = True
c.content.register_protocol_handler = False
c.content.webgl = False
c.content.webrtc_ip_handling_policy = "default-public-interface-only"
c.content.default_encoding = "utf-8"
config.set("editor.command", ["alacritty", "-e", "nvim", "{}"])

c.input.forward_unbound_keys = "all"
c.input.insert_mode.auto_leave = False
c.input.insert_mode.plugins = False

c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = "never"
c.colors.webpage.preferred_color_scheme = "dark"
bg_color = "#000000"
c.colors.webpage.bg = bg_color

c.qt.args = [
    "enable-gpu-rasterization",
    "ignore-gpu-blocklist",
    "enable-accelerated-video-decode",
]

# https://github.com/LaurenceWarne/qute-code-hint
c.hints.selectors["code"] = [
    # Selects all code tags whose direct parent is not a pre tag
    ":not(pre) > code",
    "pre",
]

# Add a specific selectors (tries to select any frame)
c.hints.selectors["frame"] = ["div", "header", "section", "nav"]
c.hints.chars = 'qwertasdfzxcv'
# Directory to save downloads to. If unset, a sensible OS-specific
# default is used.
# Type: Directory
c.downloads.location.directory = '~/Downloads'

# When to show the tab bar.
# Type: String
# Valid values:
#   - always: Always show the tab bar.
#   - never: Always hide the tab bar.
#   - multiple: Hide the tab bar if only one tab is open.
#   - switching: Show the tab bar when switching tabs.
c.tabs.position = 'bottom'
c.tabs.show = 'multiple'
c.tabs.last_close = 'default-page'

## When to show the statusbar.
## Type: String
## Valid values:
##   - always: Always show the statusbar.
##   - never: Always hide the statusbar.
##   - in-mode: Show the statusbar when in modes other than normal mode.
c.statusbar.show = 'never'

# Setting default page for when opening new tabs or new windows with
# commands like :open -t and :open -w .
c.url.default_page = str(config.configdir / "startpage.html")
# c.url.default_page = 'https://search.brave.com/'
c.url.start_pages = c.url.default_page

# AdBlock
c.content.blocking.enabled = True
c.content.blocking.method = "adblock"
c.content.blocking.whitelist = ["https://atlas.test/*"]
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://easylist.to/easylist/fanboy-social.txt",
    "https://secure.fanboy.co.nz/fanboy-annoyance.txt",
    "https://easylist-downloads.adblockplus.org/easylistdutch.txt",
    "https://easylist-downloads.adblockplus.org/abp-filters-anti-cv.txt",
    # "https://gitlab.com/curben/urlhaus-filter/-/raw/master/urlhaus-filter.txt",
    "https://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
    "https://www.i-dont-care-about-cookies.eu/abp/",
    "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt",
]

# Dracula theme
# https://github.com/evannagle/qutebrowser-dracula-theme
# Changes: Renamed file, overwriting hint colors
import dracula
dracula.blood(c, { 'font': { 'size': 11 } })

# Search engines
c.url.searchengines = {
'DEFAULT'   : 'https://search.brave.com/search?q={}',
}
with open(config.configdir / "engines", "r") as f:
   for line in f:
      line = line.strip()
      if line == "" or line.startswith("#"):
         continue
      middle = line.index(" ")
      key = line[:middle]
      url = line[middle+1:]
      if key == "DEFAULT":
         url = c.url.searchengines[url]
      c.url.searchengines[key] = url


# Bindings for normal mode
config.bind('M', 'hint links spawn mpv {hint-url}')
config.bind('Z', 'hint links spawn alacritty -e yt-dlp {hint-url}')
config.bind('t', 'set-cmd-text -s :open -t')
config.bind('xx', 'config-cycle tabs.show multiple never')
config.bind('=', 'zoom-in')
config.bind('<Ctrl-=>', 'zoom')
