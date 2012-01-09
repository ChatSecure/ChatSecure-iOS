ChatSecure
=========

ChatSecure is a very simple IM client for iOS that integrates encrypted "Off the Record" messaging support from the [libotr](http://www.cypherpunks.ca/otr/) library. It uses the [LibOrange](https://github.com/unixpickle/LibOrange) library to handle all of the OSCAR functionality and the [xmppframework](http://code.google.com/p/xmppframework/) to handle XMPP.

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

[Full List](http://en.wikipedia.org/wiki/Off-the-Record_Messaging#Client_support)

License
=========

Software License Agreement (Modified BSD License)

Copyright (c) 2011, Chris Ballinger. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL CHRIS BALLINGER BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This software additionally references or incorporates the following sources
of intellectual property, the license terms for which are set forth
in the sources themselves:

Third-party Libraries
=========

The following dependencies are bundled with the ChatSecure, but are under
terms of a separate license:

* [Cypherpunks libotr](http://www.cypherpunks.ca/otr/) - provides the core encryption capabilities
* [LibOrange](https://github.com/unixpickle/LibOrange) - handles all of the OSCAR (AIM) functionality
* [XMPPFramework](https://github.com/robbiehanson/XMPPFramework) - XMPP support
* [DTCoreText](https://github.com/Cocoanetics/DTCoreText) - prettier chat window
* [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - a nice looking progress HUD

Acknowledgements
=========

* [Nick Hum](http://nickhum.com/) - awesome icon.
* [Glyphish](http://glyphish.com/) - icons used on the tab bar.
* [Adium](http://adium.im/) - lock/unlock icon used in chat window.
* [Sergio Sánchez López](http://www.iconfinder.com/icondetails/7043/128/aim_icon) - AIM protocol icon.
* [Goxxy](http://rocketdock.com/addon/icons/3462) - Google Talk icon.