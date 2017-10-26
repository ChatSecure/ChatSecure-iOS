# Disable CocoaPods deterministic UUIDs as Pods are not checked in
ENV["COCOAPODS_DISABLE_DETERMINISTIC_UUIDS"] = "true"

# Disable Bitcode for all targets http://stackoverflow.com/a/32685434/805882
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end

platform :ios, "8.0"

use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'

abstract_target 'ChatSecureCorePods' do
  # User Interface
  pod "Appirater", '~> 2.0'
  pod 'OpenInChrome', '~> 0.0'
  pod 'JTSImageViewController', '~> 1.4'
  pod 'VTAcknowledgementsViewController', '~> 1.2'
  pod 'BButton', '~> 4.0'
  pod 'TUSafariActivity', '~> 1.0'
  pod 'ARChromeActivity', '~> 1.0'
  pod 'QRCodeReaderViewController', '~> 4.0'
  # pod 'ParkedTextField', '~> 0.3.1'
  pod 'ParkedTextField', :git => 'https://github.com/gmertk/ParkedTextField.git', :commit => '46df17a' # Swift 4


  pod 'JSQMessagesViewController', :path => 'Submodules/JSQMessagesViewController/JSQMessagesViewController.podspec'

  # Debugging
  pod 'Reveal-SDK', :configurations => ['Debug']

  # Utility
  pod 'CocoaLumberjack/Swift', '~> 3.3.0'
  # pod 'CocoaLumberjack/Swift', :git => 'https://github.com/CocoaLumberjack/CocoaLumberjack.git', :commit => 'acc32864538c5d75b41a4bfa364b1431cf89954d' # Fixes compile error on Xcode 9
  pod 'MWFeedParser', '~> 1.0'
  pod 'Navajo', '~> 0.0'
  pod 'BBlock', '~> 1.2'
  pod 'KSCrash', '~> 1.15.3'

  # Network
  pod 'CocoaAsyncSocket', '~> 7.6.0'
  pod 'ProxyKit/Client', '~> 1.2.0'
  pod 'GCDWebServer', '~> 3.4'
  # pod 'GCDWebServer/CocoaLumberjack', :git => 'https://github.com/ChatSecure/GCDWebServer.git', :branch => 'kdbertel-CocoaLumberjack3'
  pod 'CPAProxy', :path => 'Submodules/CPAProxy/CPAProxy.podspec'
  pod 'XMPPFramework', :path => 'Submodules/XMPPFramework/XMPPFramework.podspec'
  pod 'ChatSecure-Push-iOS', :path => 'Submodules/ChatSecure-Push-iOS/ChatSecure-Push-iOS.podspec'

  # Google Auth
  pod 'gtm-http-fetcher', :podspec => 'Podspecs/gtm-http-fetcher.podspec'
  pod 'gtm-oauth2', :podspec => 'Podspecs/gtm-oauth2.podspec'

  # Storage
  pod 'YapDatabase/SQLCipher', '~> 3.0.2'
  # pod 'YapDatabase/SQLCipher', :git => 'https://github.com/yapstudios/YapDatabase.git', :commit => 'd632658'
  pod 'libsqlfs/SQLCipher', :git => 'https://github.com/ChatSecure/libsqlfs.git', :branch => 'podspec-fix'
  pod 'IOCipher/GCDWebServer', :path => 'Submodules/IOCipher/IOCipher.podspec'
  pod 'YapTaskQueue/SQLCipher', :git => 'https://github.com/ChatSecure/YapTaskQueue.git', :branch => 'swift4'

  # Crypto
  pod 'SignalProtocolObjC', :path => 'Submodules/SignalProtocol-ObjC/SignalProtocolObjC.podspec'
  pod 'OTRKit', :path => 'Submodules/OTRKit/OTRKit.podspec'

  ### Moved to Carthage ###
  # pod 'AFNetworking', '~> 3.1'
  # pod 'ZXingObjC', '~> 3.0'
  # pod "SAMKeychain", '~> 1.5'
  # pod 'MBProgressHUD', '~> 1.0'
  # pod 'TTTAttributedLabel', '~> 2.0'
  # pod 'PureLayout', '~> 3.0'
  # pod 'uservoice-iphone-sdk', '~> 3.2'
  # pod 'KVOController', '~> 1.0'
  # pod 'XLForm', '~> 3.3'
  # pod 'FormatterKit/TimeIntervalFormatter', '~> 1.8.2'
  ### Moved back to CocoaPods due to Swift 3->4 issues ###
  pod 'Alamofire', '~> 4.4'
  pod 'Kvitto', '~> 1.0'


  target 'ChatSecureCore'
  target 'ChatSecureTests'
  target 'ChatSecure'
end
