Pod::Spec.new do |s|
  s.name             = 'ChatSecureCore'
  s.version          = '0.1.0'
  s.summary          = 'A short description of ChatSecureCore.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ChatSecure/ChatSecure-iOS'
  s.license          = { :type => 'GPLv3', :file => 'LICENSE' }
  s.author           = { 'Chris Ballinger' => 'chris@chatsecure.org' }
  s.source           = { :git => 'https://github.com/ChatSecure/ChatSecureCore.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ChatSecure'

  s.ios.deployment_target = '9.0'

  s.source_files = ['ChatSecure/Classes/**/*.{h,m,swift}', 'ChatSecureCore/**/*.h']
  s.public_header_files = ['ChatSecureCore/ChatSecureCore.h',
                           'ChatSecureCore/Public/*.h',]
  s.private_header_files = ['ChatSecureCore/Private/*.h']

  s.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DSQLITE_HAS_CODEC' }
  
  s.frameworks = ['UIKit', 'StoreKit']

  # User Interface
  s.dependency "Appirater", '~> 2.0'
  s.dependency 'OpenInChrome', '~> 0.0'
  s.dependency 'JTSImageViewController', '~> 1.4'
  s.dependency 'BButton', '~> 4.0'
  s.dependency 'TUSafariActivity', '~> 1.0'
  s.dependency 'ARChromeActivity', '~> 1.0'
  s.dependency 'QRCodeReaderViewController', '~> 4.0'
  s.dependency 'ParkedTextField'


  s.dependency 'JSQMessagesViewController'
  s.dependency 'LumberjackConsole'


  # Utility
  s.dependency 'CocoaLumberjack/Swift', '~> 3.5.0'
  s.dependency 'MWFeedParser', '~> 1.0'
  s.dependency 'BBlock', '~> 1.2'
  s.dependency 'HockeySDK-Source'
  s.dependency 'LicensePlist'

  # Network
  s.dependency 'CocoaAsyncSocket', '~> 7.6.0'
  s.dependency 'ProxyKit/Client', '~> 1.2.0'
  s.dependency 'GCDWebServer', '~> 3.4'
  s.dependency 'CPAProxy'
  s.dependency 'XMPPFramework/Swift'

  s.dependency 'ChatSecure-Push-iOS'

  # Storage
  # We are blocked on SQLCipher 4.0.0 migration https://github.com/ChatSecure/ChatSecure-iOS/issues/1078
  s.dependency 'SQLCipher', '~> 4.2.0'
  # Version 3.1.2 breaks YapTaskQueue 0.3.0
  s.dependency 'YapDatabase/SQLCipher', '~> 3.1.3'

  # The upstream 1.3.2 has a regression https://github.com/ChatSecure/ChatSecure-iOS/issues/1075
  s.dependency 'libsqlfs/SQLCipher'
  s.dependency 'IOCipher/GCDWebServer'
  s.dependency 'YapTaskQueue/SQLCipher'

  # Crypto
  s.dependency 'SignalProtocolObjC'
  s.dependency 'OTRKit'

  s.dependency 'Alamofire', '~> 4.4'
  s.dependency 'Kvitto', '~> 1.0'

  s.dependency "Mantle"
  s.dependency "HTMLReader", '~> 2.1.1'
  s.dependency "AFNetworking", '~> 3.1'
  s.dependency "ZXingObjC", '~> 3.6'
  s.dependency "SAMKeychain", '~> 1.5'
  s.dependency "MBProgressHUD", '~> 1.1'
  s.dependency "TTTAttributedLabel", '~> 2.0'
  s.dependency "PureLayout", '~> 3.0'
  s.dependency "KVOController", '~> 1.2'
  s.dependency "XLForm", '~> 4.0.0'
  s.dependency "FormatterKit", '~> 1.8'

  s.dependency "OTRAssets"
end
