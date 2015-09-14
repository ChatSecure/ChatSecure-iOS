platform :ios, "8.0"

use_frameworks!
inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

link_with 'ChatSecure', 'ChatSecureTests'

pod 'AFNetworking', '~> 2.6'
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
pod 'VTAcknowledgementsViewController', '~> 0.15'
pod 'PureLayout', '~> 3.0'
pod 'BButton', '~> 4.0'
pod 'uservoice-iphone-sdk', '~> 3.2'
pod 'TUSafariActivity', '~> 1.0'
pod 'ARChromeActivity', '~> 1.0'
pod 'CocoaAsyncSocket', '~> 7.4'
pod 'JTSImageViewController', '~> 1.4'
pod 'KVOController', '~> 1.0'
pod 'CRToast', '~> 0.0.8'
pod 'XLForm', '~> 3.0'
# pod 'ParkedTextField', '~> 0.1' # Need to use Swift 2.0 fork

# QR Codes
pod 'QRCodeReaderViewController', '~> 3.5.0'
pod 'ZXingObjC', '~> 3.0'


# Local Podspecs
pod 'gtm-http-fetcher', :podspec => 'Podspecs/gtm-http-fetcher.podspec'
pod 'gtm-oauth2', :podspec => 'Podspecs/gtm-oauth2.podspec'
pod 'SQLCipher/fts', :podspec => 'Podspecs/SQLCipher.podspec.json'


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
pod 'ParkedTextField', :path => 'Submodules/ParkedTextField/ParkedTextField.podspec'

