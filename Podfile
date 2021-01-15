install! 'cocoapods', :deterministic_uuids => false

# Blocked on https://github.com/CocoaLumberjack/CocoaLumberjack/issues/1105
#, :generate_multiple_pod_projects => true

platform :ios, "12.0"

use_modular_headers!
inhibit_all_warnings!

source 'https://cdn.cocoapods.org/'

workspace 'ChatSecure.xcworkspace'
project 'ChatSecure.xcodeproj', 'iOS_Debug' => :debug, 'macOS_Debug' => :debug, 'iOS_Release' => :release, 'macOS_Release' => :release

abstract_target 'ChatSecureCorePods' do  
  pod 'ZXingObjC/QRCode', :git => 'https://github.com/zxingify/zxingify-objc.git', :tag => '3.6.7'

  # Catalyst patch won't be merged upstream
  pod 'SQLCipher', :git => 'https://github.com/ChatSecure/sqlcipher.git', :branch => 'v4.4.2-catalyst'

  pod 'ParkedTextField', :git => 'https://github.com/gmertk/ParkedTextField.git', :tag => '1.0.0'
  pod 'JSQMessagesViewController', :path => 'Submodules/JSQMessagesViewController/JSQMessagesViewController.podspec'

  pod 'LumberjackConsole', :path => 'Submodules/LumberjackConsole/LumberjackConsole.podspec'

  # Network
  # pod 'CPAProxy', :path => 'Submodules/CPAProxy/CPAProxy.podspec'
  pod 'XMPPFramework/Swift', :path => 'Submodules/XMPPFramework/XMPPFramework.podspec'

  pod 'ChatSecure-Push-iOS', :path => 'Submodules/ChatSecure-Push-iOS/ChatSecure-Push-iOS.podspec'

  # The upstream 1.3.2 has a regression https://github.com/ChatSecure/ChatSecure-iOS/issues/1075
  pod 'libsqlfs/SQLCipher', :path => 'Submodules/libsqlfs/libsqlfs.podspec'

  pod 'IOCipher/GCDWebServer', :path => 'Submodules/IOCipher/IOCipher.podspec'
  pod 'YapTaskQueue/SQLCipher', :path => 'Submodules/YapTaskQueue/YapTaskQueue.podspec'

  # Crypto
  pod 'SignalProtocolObjC', :path => 'Submodules/SignalProtocol-ObjC/SignalProtocolObjC.podspec'
  pod 'OTRKit', :path => 'Submodules/OTRKit/OTRKit.podspec'

  pod 'ChatSecureCore', :path => 'ChatSecureCore.podspec'
  pod 'OTRAssets', :path => 'OTRAssets.podspec'

  target 'ChatSecureTests'
  target 'ChatSecure'
  target 'ChatSecureCore'
end


def fix_config(config)
  # https://github.com/CocoaPods/CocoaPods/issues/8069#issuecomment-420044112
  if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 12.0
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
  end
  config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
  # https://github.com/CocoaPods/CocoaPods/issues/8891
  if config.build_settings['DEVELOPMENT_TEAM'].nil?
    config.build_settings['DEVELOPMENT_TEAM'] = '4T8JLQR6GR'
  end
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.build_configurations.each do |config|
        fix_config(config)
    end
    project.targets.each do |target|
      target.build_configurations.each do |config|
        fix_config(config)
      end
    end
  end
end