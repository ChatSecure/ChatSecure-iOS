Pod::Spec.new do |s|
  s.name         = "gtm-http-fetcher"
  s.version      = "1.1"
  s.summary      = "Google Toolbox for Mac - HTTP Fetcher."
  s.description  = "The Google Toolbox for Mac OAuth 2 Controllers make it easy for Cocoa\n                    applications to sign in to services using OAuth 2 for authentication\n                    and authorization.\n\n                    This version can be used with iOS ≥ 5.0 or OS X ≥ 10.7.\n                    To target earlier versions of iOS or OS X, use\n\n                      pod 'gtm-oauth2', '~> 0.0.1'\n"
  s.homepage     = "https://github.com/google/gtm-http-fetcher"
  s.license      = 'Apache 2.0'
  s.author       = "Google"
  s.source       = { :git => "https://github.com/google/gtm-http-fetcher.git", :commit => '153254707f894962fb73232ec566c15d5aa0fe2d' }
  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.8"

  s.source_files = "Source/GTM*.{h,m}"
  s.osx.exclude_files = "Source/GTMHTTPFetcherLogViewController.{h,m}"
  s.requires_arc = false
end