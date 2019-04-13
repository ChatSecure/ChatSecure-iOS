# Disable CocoaPods deterministic UUIDs as Pods are not checked in
ENV["COCOAPODS_DISABLE_DETERMINISTIC_UUIDS"] = "true"

# Disable Bitcode for all targets http://stackoverflow.com/a/32685434/805882
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
      config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'NO'
    end
  end
end

platform :ios, "9.0"

use_frameworks!
inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

abstract_target 'ChatSecureCorePods' do
  # User Interface
  pod "Appirater", '~> 2.0'
  pod 'OpenInChrome', '~> 0.0'
  pod 'JTSImageViewController', '~> 1.4'
  pod 'BButton', '~> 4.0'
  pod 'TUSafariActivity', '~> 1.0'
  pod 'ARChromeActivity', '~> 1.0'
  pod 'QRCodeReaderViewController', '~> 4.0'
  # pod 'ParkedTextField', '~> 0.3.1'
  pod 'ParkedTextField', :git => 'https://github.com/gmertk/ParkedTextField.git', :commit => 'a3800e3' # Swift 4.2


  pod 'JSQMessagesViewController', :path => 'Submodules/JSQMessagesViewController/JSQMessagesViewController.podspec'

  # pod 'LumberjackConsole', '~> 3.3.0'
  pod 'LumberjackConsole', :path => 'Submodules/LumberjackConsole/LumberjackConsole.podspec'


  # Utility
  pod 'CocoaLumberjack/Swift', '~> 3.5.0'
  pod 'MWFeedParser', '~> 1.0'
  pod 'Navajo', '~> 0.0'
  pod 'BBlock', '~> 1.2'
  pod 'HockeySDK-Source'
  pod 'LicensePlist'

  # Network
  pod 'CocoaAsyncSocket', '~> 7.6.0'
  pod 'ProxyKit/Client', '~> 1.2.0'
  pod 'GCDWebServer', '~> 3.4'
  pod 'CPAProxy', :path => 'Submodules/CPAProxy/CPAProxy.podspec'
  pod 'XMPPFramework/Swift', :path => 'Submodules/XMPPFramework/XMPPFramework.podspec'

  pod 'ChatSecure-Push-iOS', :path => 'Submodules/ChatSecure-Push-iOS/ChatSecure-Push-iOS.podspec'

  # Google Auth
  pod 'gtm-http-fetcher', :podspec => 'Podspecs/gtm-http-fetcher.podspec'
  pod 'gtm-oauth2', :podspec => 'Podspecs/gtm-oauth2.podspec'

  # Storage
  # We are blocked on SQLCipher 4.0.0 migration https://github.com/ChatSecure/ChatSecure-iOS/issues/1078
  pod 'SQLCipher', '~> 3.4'
  # Version 3.1.2 breaks YapTaskQueue 0.3.0
  pod 'YapDatabase/SQLCipher', '3.1.1'

  # The upstream 1.3.2 has a regression https://github.com/ChatSecure/ChatSecure-iOS/issues/1075
  pod 'libsqlfs/SQLCipher', :git => 'https://github.com/ChatSecure/libsqlfs.git', :branch => '1.3.2-chatsecure'
  pod 'IOCipher/GCDWebServer', :path => 'Submodules/IOCipher/IOCipher.podspec'
  pod 'YapTaskQueue/SQLCipher', :git => 'https://github.com/ChatSecure/YapTaskQueue.git', :branch => 'swift4'

  # Crypto
  pod 'SignalProtocolObjC', :path => 'Submodules/SignalProtocol-ObjC/SignalProtocolObjC.podspec'
  pod 'OTRKit', :path => 'Submodules/OTRKit/OTRKit.podspec'

  pod 'Alamofire', '~> 4.4'
  pod 'Kvitto', '~> 1.0'

  target 'ChatSecureCore'
  target 'ChatSecureTests'
  target 'ChatSecure'
end
