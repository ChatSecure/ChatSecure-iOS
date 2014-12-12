platform :ios, "7.0"

inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

link_with 'ChatSecure', 'ChatSecureTests'

pod 'AFNetworking', '~> 2.4'
pod "Appirater", '~> 2.0'
pod 'OpenInChrome', '~> 0.0'
pod 'MWFeedParser', '~> 1.0'
pod "CocoaLumberjack", '~> 1.9'
pod "Facebook-iOS-SDK", '~> 3.19'
pod "HockeySDK", '~> 3.6'
pod "MagicalRecord", '~> 2.2'
pod 'MBProgressHUD', '~> 0.9'
pod "SSKeychain", '~> 1.2'
pod "UIAlertView-Blocks", '~> 1.0'
# pod 'gtm-oauth2', '~> 0.1.0' # Trunk is outdated, using local podspec
pod 'JTTargetActionBlock', '~> 1.0'
# pod 'YapDatabase/SQLCipher', '~> 2.5' # We need to use fork for sqlite3_rekey support 
pod 'Mantle', '~> 1.4'
pod 'Navajo', '~> 0.0'
pod 'RMStepsController', '~> 1.0'
pod 'JSQSystemSoundPlayer', '~> 1.5'
pod 'JSQMessagesViewController', '~> 5.3'
pod 'BBlock', '~> 1.2'
pod 'JVFloatLabeledTextField', '~> 0.0'
pod 'TTTAttributedLabel', '~> 1.10'
pod 'VTAcknowledgementsViewController', '~> 0.12'
pod 'PureLayout', '~> 2.0'
pod 'BButton', '~> 4.0'
pod 'uservoice-iphone-sdk', '~> 3.2'
pod 'TUSafariActivity', '~> 1.0'
pod 'ARChromeActivity', '~> 1.0'

# Local Podspecs
pod 'gtm-http-fetcher', :podspec => 'Podspecs/gtm-http-fetcher.podspec.json'
pod 'gtm-oauth2', :podspec => 'Podspecs/gtm-oauth2.podspec.json'

# Waiting for 7.4.1 to be pushed to trunk
pod 'CocoaAsyncSocket', :git => 'https://github.com/robbiehanson/CocoaAsyncSocket.git', :commit => 'c0bbcbcc5e039ca5d732f9844bf95c3d8ee31a5b'

# Forks
pod 'AFOAuth2Client', :git => 'https://github.com/ChatSecure/AFOAuth2Client.git', :branch => 'release'
pod 'SIAlertView', :git => 'https://github.com/ChatSecure/SIAlertView.git', :branch => 'attributedText'

# Submodules
pod 'ProxyKit/Client', :path => 'Submodules/ProxyKit/ProxyKit.podspec'
pod 'OTRKit', :path => 'Submodules/OTRKit/OTRKit.podspec'
pod 'CPAProxy', :path => 'Submodules/CPAProxy/CPAProxy.podspec'
pod 'XMPPFramework', :path => 'Submodules/XMPPFramework/XMPPFramework.podspec.json'
pod 'YapDatabase/SQLCipher', :path => 'Submodules/YapDatabase/YapDatabase.podspec'
