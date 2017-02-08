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
  pod 'AFNetworking', '~> 3.1'
  pod "Appirater", '~> 2.0'
  pod 'OpenInChrome', '~> 0.0'
  pod 'MWFeedParser', '~> 1.0'
  pod "CocoaLumberjack", '~> 2.3.0'
  pod 'KSCrash', '~> 1.15.3'
  pod 'MBProgressHUD', '~> 1.0'
  pod "SAMKeychain", '~> 1.5'
  # pod 'gtm-oauth2', '~> 0.1.0' # Trunk is outdated, using local podspec
  pod 'YapDatabase/SQLCipher', '~> 2.9'
  #pod 'YapDatabase/SQLCipher', :path => 'Submodules/YapDatabase/YapDatabase.podspec'

  pod 'Mantle', '~> 2.0'
  pod 'Navajo', '~> 0.0'
  # wating on 8.0 https://github.com/jessesquires/JSQMessagesViewController/pull/840
  # using for in meantime
  # pod 'JSQMessagesViewController', '~> 8.0'
  pod 'BBlock', '~> 1.2'
  pod 'JVFloatLabeledTextField', '~> 1.0'
  pod 'TTTAttributedLabel', '~> 2.0'
  pod 'VTAcknowledgementsViewController', '~> 1.2'
  pod 'PureLayout', '~> 3.0'
  pod 'BButton', '~> 4.0'
  pod 'uservoice-iphone-sdk', '~> 3.2'
  pod 'TUSafariActivity', '~> 1.0'
  pod 'ARChromeActivity', '~> 1.0'
  # We need a commit from next release
  #pod 'CocoaAsyncSocket', '~> 7.4'
  pod 'CocoaAsyncSocket', '~> 7.5.1'

  pod 'JTSImageViewController', '~> 1.4'
  pod 'KVOController', '~> 1.0'
  #Reachability only needed for YapActionItems
  pod 'Reachability', '~> 3'
  pod 'XLForm', '~> 3.3'
  #pod 'ParkedTextField', '~> 0.2'
  pod 'FormatterKit/TimeIntervalFormatter'

  # QR Codes
  pod 'QRCodeReaderViewController', '~> 4.0'
  pod 'ZXingObjC', '~> 3.0'

  pod 'SignalProtocolC', :podspec => 'https://raw.githubusercontent.com/ChatSecure/SignalProtocolC.podspec/b2b483fe1c4c66cecfc0376c496e6a58ed1939b5/SignalProtocolC.podspec'
  pod 'libsqlfs/SQLCipher', :git => 'https://github.com/ChatSecure/libsqlfs.git', :branch => 'podspec-fix'

  # Local Podspecs
  pod 'gtm-http-fetcher', :podspec => 'Podspecs/gtm-http-fetcher.podspec'
  pod 'gtm-oauth2', :podspec => 'Podspecs/gtm-oauth2.podspec'

  # Forks
  pod 'JSQMessagesViewController', :git => 'https://github.com/ChatSecure/JSQMessagesViewController', :tag => '7.3.4-send_button'

  # Use this until able to push proper podspec that depends on 2.9
  pod 'YapTaskQueue/SQLCipher', '~> 0.1.6'

  # Submodules


  pod 'SignalProtocol-ObjC', :path => 'Submodules/SignalProtocol-ObjC/SignalProtocol-ObjC.podspec'
  pod 'ChatSecure-Push-iOS', :path => 'Submodules/ChatSecure-Push-iOS/ChatSecure-Push-iOS.podspec'
  pod 'ProxyKit/Client', :path => 'Submodules/ProxyKit/ProxyKit.podspec'
  pod 'OTRKit', :path => 'Submodules/OTRKit/OTRKit.podspec'
  pod 'CPAProxy', :path => 'Submodules/CPAProxy/CPAProxy.podspec'
  pod 'XMPPFramework', :path => 'Submodules/XMPPFramework/XMPPFramework.podspec'
  pod 'IOCipher/GCDWebServer', :path => 'Submodules/IOCipher/IOCipher.podspec'
  # Waiting for Swift 2.3 changes
  pod 'ParkedTextField', :path => 'Submodules/ParkedTextField/ParkedTextField.podspec'


  target 'ChatSecureCore'
  target 'ChatSecureTests'
  target 'ChatSecure'
end
