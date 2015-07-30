platform :ios, "7.0"

inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

link_with 'ChatSecure', 'ChatSecureTests'

pod 'AFNetworking', '~> 2.4'
pod "Appirater", '~> 2.0'
pod 'OpenInChrome', '~> 0.0'
pod 'MWFeedParser', '~> 1.0'
pod "CocoaLumberjack", '~> 1.9'
pod "HockeySDK-Source", '~> 3.7'
pod 'MBProgressHUD', '~> 0.9'
pod "SSKeychain", '~> 1.2'
pod "UIAlertView-Blocks", '~> 1.0'
# pod 'gtm-oauth2', '~> 0.1.0' # Trunk is outdated, using local podspec
pod 'JTTargetActionBlock', '~> 1.0'
# pod 'YapDatabase/SQLCipher', '~> 2.5' # We need to use fork for sqlite3_rekey support
pod 'Mantle', '~> 2.0'
pod 'Navajo', '~> 0.0'
# wating on 8.0 https://github.com/jessesquires/JSQMessagesViewController/pull/840
# using for in meantime
# pod 'JSQMessagesViewController', '~> 8.0'
pod 'BBlock', '~> 1.2'
pod 'JVFloatLabeledTextField', '~> 1.0'
pod 'TTTAttributedLabel', '~> 1.10'
pod 'VTAcknowledgementsViewController', '~> 0.12'
pod 'PureLayout', '~> 2.0'
pod 'BButton', '~> 4.0'
pod 'uservoice-iphone-sdk', '~> 3.2'
pod 'TUSafariActivity', '~> 1.0'
pod 'ARChromeActivity', '~> 1.0'
pod 'CocoaAsyncSocket', '~> 7.4'
pod 'JTSImageViewController', '~> 1.4'
pod 'KVOController', '~> 1.0'

# QR Codes
pod 'QRCodeReaderViewController', '~> 3.5.0'
pod 'ZXingObjC', '~> 3.0'

pod 'XLForm', :git => 'https://github.com/xmartlabs/XLForm.git', :commit => '514807c473f013211c14c65919846044d1f72da9'

# Local Podspecs
pod 'gtm-http-fetcher', :podspec => 'Podspecs/gtm-http-fetcher.podspec.json'
pod 'gtm-oauth2', :podspec => 'Podspecs/gtm-oauth2.podspec.json'
pod 'SQLCipher/fts', :podspec => 'Podspecs/SQLCipher.podspec.json'

# Wating for update to pod needed for iPad bugs
pod 'CRToast', :git => 'https://github.com/cruffenach/CRToast', :commit => '78569d0e6e6704872af5db1bc37be0ff9d112ac0'

# Forks
pod 'SIAlertView', :git => 'https://github.com/ChatSecure/SIAlertView.git', :branch => 'attributedText'
pod 'JSQMessagesViewController', :git => 'https://github.com/ChatSecure/JSQMessagesViewController', :branch => '7.1.0-send_button'

# Submodules
pod 'ProxyKit/Client', :path => 'Submodules/ProxyKit/ProxyKit.podspec'
pod 'OTRKit', :path => 'Submodules/OTRKit/OTRKit.podspec'
pod 'CPAProxy', :path => 'Submodules/CPAProxy/CPAProxy.podspec'
pod 'XMPPFramework', :path => 'Submodules/XMPPFramework/XMPPFramework.podspec'
pod 'YapDatabase/SQLCipher', :path => 'Submodules/YapDatabase/YapDatabase.podspec'
pod 'IOCipher/GCDWebServer', :path => 'Submodules/IOCipher/IOCipher.podspec'
