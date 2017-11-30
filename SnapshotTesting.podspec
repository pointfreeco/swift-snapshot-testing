#
# Be sure to run `pod lib lint SnapshotTesting.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SnapshotTesting'
  s.version          = '0.1.0'
  s.summary          = 'Tests that save and assert against reference data'


  s.description      = <<-DESC
    Automatically record app data into test assertions. Snapshot tests capture the entirety of a data structure and cover far more surface area than a typical unit test.
                       DESC

  s.homepage         = 'https://github.com/pointfreeco/swift-snapshot-testing'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { 'Brandon Williams' => 'mbw234@gmail.com' , 
                         'Stephen Celis' => 'me@stephencelis.com' }
  s.social_media_url = 'https://twitter.com/pointfreeco'
  s.source           = { :git => 'https://github.com/pointfreeco/swift-snapshot-testing.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/**/*'
  s.frameworks = 'UIKit', 'XCTest', 'WebKit'
  
end
