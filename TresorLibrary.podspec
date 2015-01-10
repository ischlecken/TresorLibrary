#
# Be sure to run `pod lib lint TresorLibrary.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "TresorLibrary"
  s.version          = "0.1.0"
  s.summary          = "Util Classes for Tresor App."
  s.description      = <<-DESC
                       The library classes for Tresor App,
                       especially the crypto parts.
                       DESC
  s.homepage         = "https://github.com/ischlecken/TresorLibrary"
  s.license          = 'MIT'
  s.author           = { "Hugo Schlecken" => "h.schlecken@gmx.de" }
  s.source           = { :git => "https://github.com/ischlecken/TresorLibrary.git", :tag => s.version.to_s }

  s.platform         = :ios, '8.1'
  s.requires_arc     = true

  s.source_files     = 'Pod/*.{h,m}'
  s.resource_bundle  = { 'TresorLibrary' => ['Pod/*.lproj'] }
 
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

  s.subspec 'Util' do |ss|
    ss.source_files = 'Pod/Util'
  end

  s.subspec 'Crypto' do |ss|
    ss.xcconfig     = { 'OTHER_CFLAGS' => '-DUSE_SHA1' }
    ss.source_files = 'Pod/Crypto'
    ss.dependency   'TresorLibrary/Util'
  end

  s.subspec 'Dao' do |ss|
    ss.source_files = 'Pod/Dao'
    ss.resources    = 'Pod/Dao/Tresor.xcdatamodeld'
    ss.frameworks   = 'CoreData'

    ss.dependency 'PromiseKit'
    ss.dependency 'JSONModel'
    ss.dependency 'SSKeychain'
    ss.dependency 'TresorLibrary/Crypto'
    ss.dependency 'TresorLibrary/Util'
  end

  s.subspec 'Gui' do |ss|
    ss.source_files = 'Pod/Gui'
    ss.frameworks   = 'UIKit', 'AudioToolbox', 'CoreGraphics'
    ss.dependency   'SSKeychain'
    ss.dependency   'TresorLibrary/Crypto'
  end

end
