# [ChatSecure](https://github.com/ChatSecure/ChatSecure-iOS)

[![Build Status](https://travis-ci.org/ChatSecure/ChatSecure-iOS.svg?branch=master)](https://travis-ci.org/ChatSecure/ChatSecure-iOS)

[ChatSecure](https://chatsecure.org) is a free and open source instant messaging client for [iOS](https://itunes.apple.com/us/app/chatsecure/id464200063) and [Android](https://play.google.com/store/apps/details?id=info.guardianproject.otr.app.im&hl=en) that integrates encrypted [OTR](https://en.wikipedia.org/wiki/ChatSecure_Messaging) ("Off the Record") messaging support from the [libotr](https://otr.cypherpunks.ca/) library and the [XMPPFramework](https://github.com/robbiehanson/XMPPFramework/) to handle Jabber/GTalk (XMPP).


## Cost

This project is **100% free** because it is important that all people around the world have unrestricted access to privacy tools.
However, developing and supporting this project is hard work and costs real money. Please help support the development of this project! We now also accept Bitcoin via Coinbase! :)

[![bitcoin coinbase donation](https://chatsecure.org/images/bitcoin_donate.png)](https://coinbase.com/checkouts/1cf35f00d722205726f50b940786c413) [![paypal donation](https://chatsecure.org/images/paypal_donate.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=XRBHJ9AX5VWNA) 


## Localization


![transifex localization](https://www.transifex.com/projects/p/chatsecure/resource/strings/chart/image_png)

If you would like to contribute/improve a translation:

 1. Visit our [Transifex project page](https://www.transifex.net/projects/p/chatsecure/) and make an account if you don't have one already.
 2. Go to the resources subsites [AppStore.strings](https://www.transifex.net/projects/p/chatsecure/resource/appstorestrings/) & [Localizable.strings](https://www.transifex.net/projects/p/chatsecure/resource/strings/) to add a new language or improve an existing translation. 
 3. [Open an issue on Github](https://github.com/ChatSecure/ChatSecure-iOS/issues) notifying us of your translation.



## Compatibility


There's a more [full list of OTR clients on Wikipedia](https://en.wikipedia.org/wiki/Off-the-Record_Messaging#Client_support).


### Desktop

* [Adium](https://adium.im/) (Mac OS X)
* [Jitsi](https://jitsi.org) (Cross-platform)
* [Pidgin](https://pidgin.im/) (cross-platform), with [pidgin-otr](https://otr.cypherpunks.ca/index.php#downloads) plugin.

### Mobile

* [ChatSecure-Android](https://guardianproject.info/apps/chatsecure/) (formerly known as Gibberbot)
* [BEEM](http://beem-project.com/projects/beem) (Android)
* [Conversations](https://github.com/siacs/Conversations) (Android)

## Build Instructions

You'll need [Cocoapods](http://cocoapods.org) for most of our dependencies. Due to some issues with CocoaPods and Xcode 8, we need to use the pre-release version, which we'll install with `bundler` and our `Gemfile`.
    
    $ ### gem install cocoapods # Until CocoaPods is fixed use the bundle command below instead.
    $ bundle install
    
Download the source code and **don't forget** to pull down all of the submodules as well.

    $ git clone https://github.com/ChatSecure/ChatSecure-iOS.git
    $ cd ChatSecure-iOS/
    $ git submodule update --init --recursive
    
Now you'll need to build the dependencies.
    
    $ bash ./Submodules/CPAProxy/scripts/build-all.sh
    $ bash ./Submodules/OTRKit/scripts/build-all.sh
    $ ### pod install # Until CocoaPods is fixed use the bundle commands below instead.
    $ bundle exec pod repo update
    $ bundle exec pod install
    
Next you'll need to create your own version of environment-specific data. Make a copy of `Secrets-template.plist` as `Secrets.plist`:

    $ cp OTRResources/Secrets-template.plist OTRResources/Secrets.plist
    $ cp ./configurations/OTR_Codesigning.xcconfig.sample ./configurations/OTR_Codesigning.xcconfig
    
Then set your own value for `PROVISIONING_PROFILE_Debug` in `OTR_Codesigning.xcconfig` to your iOS team provisioning profile identifier to run it on your device. You can get this identifier by temporarily selecting the desired profile in Xcode (Build Settings -> Provisiong Profile), then selecting "Other...".

Open `ChatSecure.xcworkspace` in Xcode and build. 

*Note*: **Don't open the `.xcodeproj`** because we use Cocoapods now!

If you're still having trouble compiling check out the Travis-CI build status and `.travis.yml` file.

## Contributing

Thank you for your interest in contributing to ChatSecure! To avoid potential legal headaches and to allow distribution on Apple's App Store please sign our CLA (Contributors License Agreement). For contributing translations, please check out our [Transifex](https://www.transifex.com/projects/p/chatsecure/) page.

1. Sign the CLA ([odt](https://github.com/ChatSecure/ChatSecure-iOS/raw/master/media/contributing/CLA.odt), [pdf](https://github.com/ChatSecure/ChatSecure-iOS/raw/master/media/contributing/CLA.pdf)) and email it to [chris@chatsecure.org](mailto:chris@chatsecure.org).
2. [Fork](https://github.com/ChatSecure/ChatSecure-iOS/fork) the project and (preferably) work in a feature branch.
3. Open a [pull request](https://github.com/ChatSecure/ChatSecure-ios/pulls) on GitHub.
4. Thank you!

## License


	Software License Agreement (GPLv3+)
	
	Copyright (c) 2015, Chris Ballinger. All rights reserved.
	
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

## Third-party Libraries

This software additionally references or incorporates the following sources
of intellectual property, the license terms for which are set forth
in the sources themselves:

The following dependencies are bundled with the ChatSecure, but are under
terms of a separate license:

* [OTRKit](https://github.com/chatsecure/otrkit) - Objective-C libotr wrapper library for OTR encryption [![Build Status](https://travis-ci.org/ChatSecure/OTRKit.svg?branch=master)](https://travis-ci.org/ChatSecure/OTRKit)
	* [libotr](https://otr.cypherpunks.ca/) - provides the core message encryption capabilities
	* [libgcrypt](https://www.gnu.org/software/libgcrypt/) - handles core libotr encryption routines
	* [libgpg-error](http://www.gnupg.org/related_software/libgpg-error/) - error codes used by libotr
* [CPAProxy](https://github.com/ursachec/CPAProxy) - Objective-C Tor Wrapper Framework for iOS [![Build Status](https://travis-ci.org/ursachec/CPAProxy.svg?branch=master)](https://travis-ci.org/ursachec/CPAProxy)
	* [OpenSSL](https://www.openssl.org) - crypto primitives required by Tor
	* [libevent](http://libevent.org) - Tor i/o dependency
	* [Tor](https://www.torproject.org) - internet anonymity framework 
* [XMPPFramework](https://github.com/robbiehanson/XMPPFramework) - XMPP support
* [YapDatabase](https://github.com/yapstudios/YapDatabase) - YapDatabase is a pretty awesome key/value/collection store built atop sqlite for iOS & Mac.
	* [SQLCipher](https://www.zetetic.net/sqlcipher/) - full database encryption for [sqlite](http://sqlite.org)
* [Mantle](https://github.com/mantle/mantle) - Model framework for Cocoa and Cocoa Touch
* [JSQMessagesViewController](https://github.com/jessesquires/JSQMessagesViewController) - Messages UI library for iOS
* [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - a nice looking progress HUD
* [MWFeedParser](https://github.com/mwaterfall/MWFeedParser) - Methods for escaping HTML strings
* [SSKeychain](https://github.com/soffes/sskeychain) - Utilities to store passwords securely in the iOS keychain
* [Appirater](https://github.com/arashpayan/appirater) - nags people to give reviews
* [UserVoice](https://www.uservoice.com/) - in-app support forum
* [HockeySDK](https://github.com/bitstadium/HockeySDK-iOS) - crash reporting framework
* [DAKeyboardControl](https://github.com/danielamitay/DAKeyboardControl) - support for swiping down keyboard in chat view

For a more complete list, check the [Podfile](https://github.com/ChatSecure/ChatSecure-iOS/blob/master/Podfile).

## Acknowledgements

Thank you to everyone who helped this project become a reality! This project is also supported by the fine folks from [The Guardian Project](https://guardianproject.info) and [OpenITP](https://openitp.org).

* [Nick Hum](http://nickhum.com/) - awesome icon.
* [Icons8](http://icons8.com/license) - Various new "iOS 7"-style icons
* [Mateo Zlatar](http://thenounproject.com/mateozlatar/) - [World Icon](http://thenounproject.com/term/world/6502/)
* [Goxxy](http://rocketdock.com/addon/icons/3462) - Google Talk icon.
* Yes designed by [Kristin Hogan](http://www.thenounproject.com/khogan87) from the [Noun Project](http://www.thenounproject.com)
* No designed by [Kristin Hogan](http://www.thenounproject.com/khogan87) from the [Noun Project](http://www.thenounproject.com)
* Wifi designed by [useiconic.com](http://thenounproject.com/useiconic.com/) from the [Noun Project](http://www.thenounproject.com)
* Warning designed by [Lorena Salagre](http://thenounproject.com/lorens/) from the [Noun Project](http://www.thenounproject.com)
* [Localizations](https://www.transifex.com/projects/p/chatsecure/)
	* [Jiajuan Lin](http://www.personal.psu.edu/jwl5262/blogs/lin_portfolio/) (Chinese)
	* [Jan-Christoph Borchardt](http://jancborchardt.net/) (German)
	* [vitalyster](https://github.com/vitalyster) (Russian)
	* [burhan teoman](https://www.transifex.net/accounts/profile/burhanteoman/) (Turkish)
	* [shikibiomernok](https://www.transifex.net/accounts/profile/shikibiomernok/) (Hungarian)
* Many many more!
