To do:
* Remove user passwords from logging (Do this by replacing subshells with regular source scripts, and those files will add to outarr instead of echo out)
* Figure out why G:Maps returns 503 to url-title-get module
* Figure out how to print bold/italics/underlines/colors
* Add a way to do multiple seds at once (pipe separated perhaps? i.e. > s/tant/tent/ | s/itds/its)
* Improve Amazon price scraping
* Modify grodt.sh to kickban any user that uses the nick 'goose' in a derogatory statement, that is not on a white list (basically any #atlanta regular)
* Add method for changing user flags
* Add documentation of how factoids work
* Add UID for factoids
* Add a way to modify/delete one reply value of a factoid with multiple reply values, rather than having to delete the entire factoid
* Add failed login notifications
* Add a setting to require being logged in to interact with the bot at all
* Add wolf/mafia game module
* Add a module which spell checks every word
* Add Cards Against Humanity module
* Add Choose Your Own Adventure module or factoid set
* Add some kind of "prize for karma" system
* Add weather underground search module
* Add an urban dictionary search module
* Add google images search module
* Add Imgur search module
* Add an SMS module
* Add flood protection
* Add bold to sed module
* Add a !comic function
* Add Dropbox to url-title-get
* Add GitHub to url-title-get
* Add NetFlix to url-title-get
* Add Twitch.TV to url-title-get
* Add PCPartPicker to url-title-get
* Add ThePirateBay to url-title-get
* Add Vine to url-title-get
* Add IMDB to url-title-get
* Add Urban Dictionary to url-title-get
* Add profiles to Imgur in url-title-get
* Add gfycat to url-title-get
* If an addressed command does not match a known command prefix, check for modules that require regex matching. If that fails, check for factoids.
* &feature=youtu.be shouldn't fuck up youtube links in url-title-get
* Implement an "unforget" command for factoids
* Improve sed module to allow escaped characters
* Add a factstats command
* Fix seen if target is not found announcement
