ChatSecure
=========

ChatSecure is an instant messaging client for iOS that integrates encrypted "Off the Record" messaging support from the [libotr](http://www.cypherpunks.ca/otr/) library. It uses the [LibOrange](https://github.com/unixpickle/LibOrange) library to handle all of the AIM (OSCAR) functionality and the [XMPPFramework](https://github.com/robbiehanson/XMPPFramework/) to handle Jabber/GTalk (XMPP).


Cost
=========

This project is \***100% free**\* because it is important that all people around the world have unrestricted access to privacy tools.
However, developing and supporting this project is hard work and costs real money. Please help support the development of this project!

[![donation](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=XRBHJ9AX5VWNA)


Localization
=========

If you would like to contribute/improve a translation:

 1. Visit our [Transifex project page](https://www.transifex.net/projects/p/chatsecure/) and make an account if you don't have one already.
 2. Go to the resources subsites [AppStore.strings](https://www.transifex.net/projects/p/chatsecure/resource/appstorestrings/) & [Localizable.strings](https://www.transifex.net/projects/p/chatsecure/resource/strings/) to add a new language or improve an existing translation. 
 3. [Open an issue on Github](https://github.com/chrisballinger/Off-the-Record-iOS/issues) notifying us of your translation.
 

 
Compatibility
=========

**Bold** indicates it has been tested and works properly.

Native
------
* **[Adium](http://adium.im/) (Mac OS X) - OTR works over both XMPP and Oscar.**
* climm (Unix-like), since (mICQ) 0.5.4.
* MCabber (Unix-like), since 0.9.4
* CenterIM (Unix-like), since 4.22.2
* Phoenix Viewer (successor of Emerald Viewer), a Second Life client (Cross-platform)
* Vacuum IM (Cross-platform)
* Jitsi (Cross-platform)
* BitlBee (Cross-platform), since 3.0 (optional at compile-time)

Plug-in
------
* [Pidgin](http://pidgin.im/) (cross-platform), with [pidgin-otr](http://www.cypherpunks.ca/otr/index.php#downloads) plugin.
* Kopete (Unix-like), either with a third-party plugin or, since the addition of Kopete-OTR on 12th of March 2008, with the version of Kopete shipped with KDE 4.1.0 and later releases.
* Miranda IM (Microsoft Windows), with a third-party plugin
* Psi (Cross-platform), with a third-party plugin and build, in Psi+ native usable
* Trillian (Microsoft Windows), with a third-party plugin
* irssi, with a third-party plugin

Proxy (download [here](http://www.cypherpunks.ca/otr/index.php#downloads))
------
* AOL Instant Messenger (Mac OS X, Microsoft Windows)
* iChat (Mac OS X)
* Proteus (Mac OS X)

Phone apps
------
* [Gibberbot](https://guardianproject.info/apps/gibber/) (formerly OtRChat), a free and open source Android application (still in early development) produced by The Guardian Project, provides OTR protocol compatible over XMPP chat.
* [BEEM](http://beem-project.com/projects/beem) - Android XMPP client (compatibility unknown)

[Full List](http://en.wikipedia.org/wiki/Off-the-Record_Messaging#Client_support)

License
=========

	Software License Agreement (GPLv3+)
	
	Copyright (c) 2012, Chris Ballinger. All rights reserved.
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

If you would like to relicense this code to sell it on the App Store, 
please contact me at [chris@chatsecure.org](mailto:chris@chatsecure.org).

This software additionally references or incorporates the following sources
of intellectual property, the license terms for which are set forth
in the sources themselves:

Third-party Libraries
=========

The following dependencies are bundled with the ChatSecure, but are under
terms of a separate license:

* [libotr](http://www.cypherpunks.ca/otr/) - provides the core message encryption capabilities
	* [libgcrypt](http://www.gnu.org/software/libgcrypt/) - handles core libotr encryption routines
	* [libgpg-error](http://www.gnupg.org/related_software/libgpg-error/) - error codes used by libotr
* [LibOrange](https://github.com/unixpickle/LibOrange) - handles all of the OSCAR (AIM) functionality
* [XMPPFramework](https://github.com/robbiehanson/XMPPFramework) - XMPP support
* [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - a nice looking progress HUD
* [MWFeedParser](https://github.com/mwaterfall/MWFeedParser) - Methods for escaping HTML strings
* [Crittercism](http://www.crittercism.com/) - crash reports, only submitted via opt-in
* [SFHFKeychainUtils](https://github.com/ldandersen/scifihifi-iphone/tree/master/security/) - Utilities to store passwords securely in the iOS keychain
* [Appirater](https://github.com/arashpayan/appirater) - nags people to give reviews


Acknowledgements
=========

* [Nick Hum](http://nickhum.com/) - awesome icon.
* [Glyphish](http://glyphish.com/) - icons used on the tab bar.
* [Adium](http://adium.im/) - lock/unlock icon used in chat window, status gems.
* [Sergio Sánchez López](http://www.iconfinder.com/icondetails/7043/128/aim_icon) - AIM protocol icon.
* [Goxxy](http://rocketdock.com/addon/icons/3462) - Google Talk icon.
* [Localizations](https://www.transifex.com/projects/p/chatsecure/)
	* [Jiajuan Lin](http://www.personal.psu.edu/jwl5262/blogs/lin_portfolio/) (Chinese)
	* [Jan-Christoph Borchardt](http://jancborchardt.net/) (German)
	* [vitalyster](https://github.com/vitalyster) (Russian)
	* [burhan teoman](https://www.transifex.net/accounts/profile/burhanteoman/) (Turkish)
	* [shikibiomernok](https://www.transifex.net/accounts/profile/shikibiomernok/) (Hungarian)