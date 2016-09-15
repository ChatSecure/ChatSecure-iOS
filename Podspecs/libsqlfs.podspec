Pod::Spec.new do |s|
  s.name             = "libsqlfs"
  s.version          = "1.3"
  s.summary          = "Library that implements a POSIX style filesystem on top of an SQLite database"
  s.description      = <<-DESC
                        The libsqlfs library implements a POSIX style file system on top of an
                        SQLite database.  It allows applications to have access to a full read/write
                        file system in a single file, complete with its own file hierarchy and name
                        space.  This is useful for applications which needs structured storage, such
                        as embedding documents within documents, or management of configuration
                        data or preferences.
                       DESC
  s.homepage         = "https://github.com/guardianproject/libsqlfs"
  s.license          = { :type => 'LGPLv2.1', :file => 'COPYING' }
  s.author           = { "Chris Ballinger" => "chris@chatsecure.org" } # Podspec author
  s.source           = { :git => "https://github.com/guardianproject/libsqlfs.git", :tag => "v1.3" }
  s.social_media_url = 'https://twitter.com/guardianproject'

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.8'

  s.requires_arc = true

  s.default_subspec = 'standard'

  s.prepare_command = 'mv sqlfs.c sqlfs.m'

  s.subspec 'common' do |ss|
    ss.source_files = 'sqlfs.{h,m}', 'sqlfs_internal.h'
  end

  # use a builtin version of sqlite3
  s.subspec 'standard' do |ss|
    ss.library = 'sqlite3'
    ss.dependency 'libsqlfs/common'
  end

  # use SQLCipher and enable -DHAVE_LIBSQLCIPHER flag
  s.subspec 'SQLCipher' do |ss|
    ss.dependency 'SQLCipher', '~> 3.4.0'
    ss.dependency 'libsqlfs/common'
    ss.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DHAVE_LIBSQLCIPHER -DSQLITE_HAS_CODEC' }
  end
end
