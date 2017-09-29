Pod::Spec.new do |s|
  s.name         = "gtm-oauth2"
  s.version      = "1.1"
  s.summary      = "Google Toolbox for Mac - OAuth 2 Controllers"
  s.description  = "The Google Toolbox for Mac OAuth 2 Controllers make it easy for Cocoa\n                    applications to sign in to services using OAuth 2 for authentication\n                    and authorization.\n\n                    This version can be used with iOS ≥ 5.0 or OS X ≥ 10.7.\n                    To target earlier versions of iOS or OS X, use\n\n                      pod 'gtm-oauth2', '~> 0.0.1'\n"
  s.homepage     = "https://github.com/google/gtm-oauth2"
  s.license      = 'Apache 2.0'
  s.author       = "Google"
  s.source       = { :git => "https://github.com/google/gtm-oauth2.git", :commit => '45e7fb4a302cb1dd709c0230cddea1cf60726f2e' }
  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.8"

  s.source_files = "Source/*.{h,m}"
  s.ios.source_files = "Source/Touch/*.{h,m}"
  # Xibs are too old, and we will be removing this entirely anyway
  # s.ios.resources = "Source/Touch/*.xib"
  s.osx.source_files = "Source/Mac/*.{h,m}"
  # s.osx.resources = "Source/Mac/*.xib"
  s.requires_arc = false

  # See https://github.com/google/google-api-objectivec-client/issues/88#issuecomment-130027861
  s.compiler_flags = '-DGTM_USE_SESSION_FETCHER=0'
  s.xcconfig = { :OTHER_CFLAGS => "$(inherited) -DGTM_USE_SESSION_FETCHER=0"}

  s.frameworks = 'Security', 'SystemConfiguration'
  s.dependency 'gtm-http-fetcher', '~> 1.1'
end