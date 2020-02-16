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

  # s.subspec 'Source' do |ss|
  #   ss.source_files = ['ChatSecure/Classes/**/*.{h,m,swift}', 'ChatSecureCore/**/*.h']
  #   ss.public_header_files = ['ChatSecureCore/ChatSecureCore.h',
  #                            'ChatSecureCore/Public/*.h',]
  #   ss.private_header_files = ['ChatSecureCore/Private/*.h']

  #   ss.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DSQLITE_HAS_CODEC' }
    
  #   ss.frameworks = ['UIKit', 'StoreKit']
  # end

  s.module_name = 'ChatSecureCorePod'

  # User Interface
  s.dependency 'OpenInChrome', '~> 0.0'
  s.dependency 'JTSImageViewController', '~> 1.4'
  s.dependency 'BButton', '~> 4.0'
  s.dependency 'ARChromeActivity', '~> 1.0'
  s.dependency 'QRCodeReaderViewController', '~> 4.0'
  s.dependency 'ParkedTextField'

  s.dependency 'JSQMessagesViewController'
  s.dependency 'LumberjackConsole'

  # Utility
  s.dependency 'CocoaLumberjack/Swift', '~> 3.6.0'
  s.dependency 'MWFeedParser', '~> 1.0'
  s.dependency 'BBlock', '~> 1.2'
  s.dependency 'LicensePlist'

  # Network
  s.dependency 'CocoaAsyncSocket', '~> 7.6.0'
  s.dependency 'ProxyKit/Client', '~> 1.2.0'
  s.dependency 'GCDWebServer', '~> 3.4'
  s.dependency 'CPAProxy'
  s.dependency 'XMPPFramework/Swift'

  s.dependency 'ChatSecure-Push-iOS'

  s.dependency 'SQLCipher', '~> 4.2.0'
  s.dependency 'YapDatabase/SQLCipher', '~> 3.1.3'

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
  s.dependency "AFNetworking/Security", '~> 3.1'
  s.dependency "ZXingObjC/QRCode", '~> 3.6'
  s.dependency "SAMKeychain", '~> 1.5'
  s.dependency "MBProgressHUD", '~> 1.1'
  s.dependency "TTTAttributedLabel", '~> 2.0'
  s.dependency "PureLayout", '~> 3.0'
  s.dependency "KVOController", '~> 1.2'
  s.dependency "XLForm", '~> 4.1'
  s.dependency "FormatterKit/TimeIntervalFormatter", '~> 1.8'
  s.dependency "FormatterKit/UnitOfInformationFormatter", '~> 1.8'

  s.dependency "OTRAssets"
end
