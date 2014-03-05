ChatSecure
=========

ChatSecure is a free and open source instant messaging client for [iOS](https://itunes.apple.com/us/app/chatsecure/id464200063) and [Android](https://play.google.com/store/apps/details?id=info.guardianproject.otr.app.im&hl=en) that integrates encrypted [OTR](https://en.wikipedia.org/wiki/Off-the-Record_Messaging) ("Off the Record") messaging support from the [libotr](https://otr.cypherpunks.ca/) library and the [XMPPFramework](https://github.com/robbiehanson/XMPPFramework/) to handle Jabber/GTalk (XMPP).


Cost
=========

This project is **100% free** because it is important that all people around the world have unrestricted access to privacy tools.
However, developing and supporting this project is hard work and costs real money. Please help support the development of this project! We now also accept Bitcoin via Coinbase! :)

[![bitcoin](https://chatsecure.org/images/bitcoin_donate.png)](https://coinbase.com/checkouts/1cf35f00d722205726f50b940786c413) [![donation](https://chatsecure.org/images/paypal_donate.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=XRBHJ9AX5VWNA) 


Localization
=========

![transifex localization](https://www.transifex.com/projects/p/chatsecure/resource/strings/chart/image_png)

If you would like to contribute/improve a translation:

 1. Visit our [Transifex project page](https://www.transifex.net/projects/p/chatsecure/) and make an account if you don't have one already.
 2. Go to the resources subsites [AppStore.strings](https://www.transifex.net/projects/p/chatsecure/resource/appstorestrings/) & [Localizable.strings](https://www.transifex.net/projects/p/chatsecure/resource/strings/) to add a new language or improve an existing translation. 
 3. [Open an issue on Github](https://github.com/chrisballinger/Off-the-Record-iOS/issues) notifying us of your translation.



Compatibility
=========

**Bold** indicates it has been tested and works properly.

Native
------
* **[Adium](https://adium.im/) (Mac OS X) - OTR works over both XMPP and Oscar.**
* Jitsi (Cross-platform)

Plug-in
------
* [Pidgin](https://pidgin.im/) (cross-platform), with [pidgin-otr](https://otr.cypherpunks.ca/index.php#downloads) plugin.

Phone apps
------
* **[ChatSecure Android](https://guardianproject.info/apps/chatsecure/) (formerly known as Gibberbot)**, a free and open source Android application produced by The Guardian Project, provides OTR protocol compatible over XMPP chat.
* [BEEM](http://beem-project.com/projects/beem) - Android XMPP client (compatibility unknown)

[Full List](https://en.wikipedia.org/wiki/Off-the-Record_Messaging#Client_support)

Build Instructions
========
Install [mogenerator](http://rentzsch.github.io/mogenerator/) in order to regenerate the Core Data model files. You'll also need [Cocoapods](http://cocoapods.org) for some of our dependencies.
    
    $ brew install mogenerator
    $ gem install cocoapods
    
Download the source code and **don't forget** to pull down all of the submodules as well.

    $ git clone git@github.com:chrisballinger/Off-the-Record-iOS.git
    $ cd Off-the-Record-iOS/
    $ git submodule update --init --recursive
    $ pod
    
Make your own version of environment-specific data. Make `OTRSecrets.m` file with blank API keys, and set your provisioning profile ID in `OTR_Codesigning.xcconfig`. To find the provisioning profile ID, go to Project Settings -> Build Settings -> Code Signing -> Select Provisiong Profile -> Select Other -> Copy Profile's UUID into `OTR_Codesigning.xcconfig`.

    $ cp "Off the Record/OTRSecrets-Template.m" "Off the Record/OTRSecrets.m"
    $ cp "Off the Record/configurations/OTR_Codesigning.xcconfig.sample" "Off the Record/configurations/OTR_Codesigning.xcconfig"

    
Open `Off the Record.xcworkspace` in Xcode and build. Note that you don't open the .xcodeproj anymore because we use Cocoapods now.

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

If you would like to relicense this code to distribute it on the App Store, 
please contact me at [chris@chatsecure.org](mailto:chris@chatsecure.org).

Contributing
------------

Thank you for your interest in contributing to ChatSecure! To avoid potential legal headaches and to allow distribution on Apple's App Store please sign our CLA (Contributors License Agreement). For contributing translations, please check out our [Transifex](https://www.transifex.com/projects/p/chatsecure/) page.

1. Sign the CLA ([odt](https://github.com/chrisballinger/Off-the-Record-iOS/raw/master/media/contributing/CLA.odt), [pdf](https://github.com/chrisballinger/Off-the-Record-iOS/raw/master/media/contributing/CLA.pdf)) and email it to [chris@chatsecure.org](mailto:chris@chatsecure.org).
2. [Fork](https://github.com/chrisballinger/Off-the-Record-iOS/fork) the project and (preferably) work in a feature branch.
3. Open a [pull request](https://github.com/chrisballinger/off-the-record-ios/pulls) on GitHub.
4. Thank you!


Third-party Libraries
=========

This software additionally references or incorporates the following sources
of intellectual property, the license terms for which are set forth
in the sources themselves:

The following dependencies are bundled with the ChatSecure, but are under
terms of a separate license:

* [libotr](https://otr.cypherpunks.ca/) - provides the core message encryption capabilities
* [libgcrypt](https://www.gnu.org/software/libgcrypt/) - handles core libotr encryption routines
* [libgpg-error](http://www.gnupg.org/related_software/libgpg-error/) - error codes used by libotr
* [LibOrange](https://github.com/unixpickle/LibOrange) - handles all of the OSCAR (AIM) functionality
* [XMPPFramework](https://github.com/robbiehanson/XMPPFramework) - XMPP support
* [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - a nice looking progress HUD
* [MWFeedParser](https://github.com/mwaterfall/MWFeedParser) - Methods for escaping HTML strings
* [Crittercism](https://www.crittercism.com/) - crash reports, only submitted via opt-in
* [SSKeychain](https://github.com/soffes/sskeychain) - Utilities to store passwords securely in the iOS keychain
* [Appirater](https://github.com/arashpayan/appirater) - nags people to give reviews
* [MagicalRecord](https://github.com/magicalpanda/MagicalRecord) - Core Data convenience methods
* [encrypted-core-data](https://github.com/project-imas/encrypted-core-data) - Core Data + SQLCipher
* [UserVoice](https://www.uservoice.com/) - in-app support forum
* [mogenerator](https://github.com/rentzsch/mogenerator) - creates class files for core data model
* [DAKeyboardControl](https://github.com/danielamitay/DAKeyboardControl) - support for swiping down keyboard in chat view

Acknowledgements
=========

Thank you to everyone who helped this project become a reality! This project is also supported by the fine folks from [The Guardian Project](https://guardianproject.info) and [OpenITP](https://openitp.org).

* [Nick Hum](http://nickhum.com/) - awesome icon.
* [Glyphish](http://glyphish.com/) - icons used on the tab bar.
* [Adium](https://adium.im/) - lock/unlock icon used in chat window, status gems.
* [Sergio Sánchez López](https://www.iconfinder.com/icons/7043/aim_icon) - AIM protocol icon.
* [Mateo Zlatar](http://thenounproject.com/mateozlatar/) - [World Icon](http://thenounproject.com/term/world/6502/)
* [Goxxy](http://rocketdock.com/addon/icons/3462) - Google Talk icon.
* [AcaniChat](https://github.com/acani/AcaniChat) - help on setting up chat view input box
* [Localizations](https://www.transifex.com/projects/p/chatsecure/)
	* [Jiajuan Lin](http://www.personal.psu.edu/jwl5262/blogs/lin_portfolio/) (Chinese)
	* [Jan-Christoph Borchardt](http://jancborchardt.net/) (German)
	* [vitalyster](https://github.com/vitalyster) (Russian)
	* [burhan teoman](https://www.transifex.net/accounts/profile/burhanteoman/) (Turkish)
	* [shikibiomernok](https://www.transifex.net/accounts/profile/shikibiomernok/) (Hungarian)
* Many many more!
