Pod::Spec.new do |s|
  s.name             = 'OTRAssets'
  s.version          = '0.1.0'
  s.summary          = 'A short description of OTRAssets.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ChatSecure/ChatSecure-iOS'
  s.license          = { :type => 'GPLv3', :file => 'LICENSE' }
  s.author           = { 'Chris Ballinger' => 'chris@chatsecure.org' }
  s.source           = { :git => 'https://github.com/ChatSecure/ChatSecureCore.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ChatSecure'

  s.ios.deployment_target = '9.0'

  s.source_files = 'OTRAssets/**/*.{h,m,swift}'
  s.private_header_files = 'OTRAssets/OTRLanguageManager_Private.h'
  
  s.frameworks = 'UIKit'

end
