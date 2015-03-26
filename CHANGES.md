# ChatSecure Changelog

## Version 3.1 (in progress)

* Media messaging via OTRDATA
* Media storage inside IOCipher container
* Better UX for connection status
* Bug fixes

## Version 3.0 (Dec 12, 2014)

* Message archiving with SQLCipher support (using YapDatabase)
* Tor support for XMPP
* XMPP account creation
* Updated UI for iOS 8 and new iPhones
* Major internal refactoring

## Version 2.2.4 (Mar 18, 2014)

* Require TLS for all XMPP connections

## Version 2.2.3 (Mar 11, 2014)

* Fix SSL pinning
* Fix missing chat view on iOS 6

## Version 2.2.2 (Mar 06, 2014)

* Crash fixes
* Show warning when running on insecure iOS versions

Full changelog: https://github.com/chrisballinger/Off-the-Record-iOS/compare/v2.2.1...v2.2.2

## Version 2.2.1 (Feb 27, 2014)

* Remove AIM support (sorry!)
* Crash fixes
* Minor UI fixes
* Updated localizations
* Security improvements

Full changelog: https://github.com/chrisballinger/Off-the-Record-iOS/compare/v2.2...v2.2.1

## Version 2.2 (Jan 22, 2014)

* XMPP: SSL Certificate Pinning
* XMPP: Support for non-standard root CAs like CACert to support jabber.ccc.de
* XMPP: Better support for self-signed SSL certificates via certificate pinning
* Support auto-login for accounts
* User interface improvements
* Security improvements
* Internal refactoring and code cleanup
* Fix many crashes
* Update 3rd party libraries

## Version 2.1.2 (Nov 15, 2013)

* Fix Facebook login issues
* Fix non-Gmail Google Apps for Domain login issues
* Fix issue with erroneous SSL validation error
* Fix missing keyboard / chat input area
* Fix crash when quickly switching between buddies
* Fix 100% CPU usage bug

## Version 2.1.1 (Nov 11, 2013)

* Localization updates
* Fixes for delivery receipts
* Fix OTR negotiation with ChatSecure-Android
* Opportunistic OTR support
* iOS 6 Sharing Sheet
* Fix Facebook account disconnection crash
* Fix QR code sharing
* Fix XMPP SSL hostname mismatch and self-signed cert switches
* Fix various UI bugs

Full changelog: https://github.com/chrisballinger/Off-the-Record-iOS/compare/v2.1...v2.1.1

## Version 2.1 (Oct 30, 2013)

- iOS 7 Support!
- Bug Fixes 
- Security improvements 
- Added OAuth Support for GTalk & Facebook
- 2-factor Authentication support for GTalk accounts
- Fixes Facebook login errors (now requires OAuth) 
- Updated localizations
- Asynchronous OTR private key generation 
- Replace Crittercism with HockeySDK for open source opt-in crash reporting

Note: For GTalk and Facebook accounts you'll need to reauthorize using OAuth instead of username & password.

Full changelog: https://github.com/chrisballinger/Off-the-Record-iOS/compare/v2.0.1...v2.1

## Version 2.0.1 (Jun 28, 2013)

- Attempt to fix some of the new crashes introduced in v2.0.

## Version 2.0 (Jun 04, 2013)

- New UI design
- Updated translations
- Major internal changes that will make the app easier to improve in the future
- Add buddies
- Search buddy list
- Groups
- View buddy info on long press

## Version 1.5.2 (Feb 15, 2013)

* Add UserVoice support forum
* Add Donate Button (yay!)
* Update Translations
* Add advanced XMPP security options (allow plaintext auth, require TLS)

## Version 1.5.1 (Jan 02, 2013)

* Fixes crash on launch bug
* Fixes language switcher not working

## Version 1.5 (Dec 14, 2012)

* Better fingerprint verification 
* In-app localization switching for languages not supported by iOS natively (e.g. Tibetan)
* Update translations
* Minor UI improvements
* Remove all references to a certain company's trademarks
* Update XMPPFramework (might fix connection issues to custom XMPP servers)

## Version 1.4 (Nov 05, 2012)

* Redesigned login view to be more flexible and extensible
* Added a port field to assist in connection to custom XMPP servers
* Try to fix a crash associated with Oscar logins
* Implemented two new optional XMPP features:
1) XEP-0085: Chat State Notifications
2) XEP-0184: Message Delivery Receipts

## Version 1.3 (Sep 24, 2012)

* Multiple simultaneous account support! (Facebook, GTalk, AIM, XMPP)
* Option to remember account passwords in iOS keychain
* User interface improvements
* Many, many bug fixes
* Upgrade to libotr 4.0.0
* iOS 6 and iPhone 5 support
* Removes support for armv6 devices and now has a minimum requirement of iOS 4.3. Sorry!

## Version 1.2 (Jun 02, 2012)

Check out the full changelog here: https://github.com/chrisballinger/Off-the-Record-iOS/commits/v1.2

=== Background messaging support ===
* You can receive messages in the background for 10 minutes.

=== Localizations ===
* Feel free to contribute a translation if it is incomplete or missing: https://www.transifex.net/projects/p/chatsecure/

=== Settings panel ===
* Choose your font size!

=== Share ===
* Share a link to the app via SMS, E-mail or QR-code.

=== Bug fixes ===
* Let us know if you find any bugs by using Github Issues. Please contact us directly for anything security related.

## Version 1.1 (Apr 04, 2012)

Full changelog here: https://github.com/chrisballinger/Off-the-Record-iOS/commits/v1.1
* (Retina) iPad support!
* Many bug fixes
* Converted to ARC
* Update XMPPFramework, MBProgressHUD
* Remove DTCoreText

## Version 1.0.2 (Mar 06, 2012)

* Added option to save username
* Fix some issues when sending/receiving messages over XMPP
* Multiline chat input
* Better behavior when receiving messages
* Add Initiate OTR button

Full changelog here: https://github.com/chrisballinger/Off-the-Record-iOS/commits/v1.0.2

## Version 1.0.1 (Dec 22, 2011)

* Attempt to fix an issue where AIM buddies did not appear
* Redesigned buddy list

## Version 1.0 (Dec 17, 2011)

* Initial Release