Pod::Spec.new do |spec|

  spec.name         = "SnapshotTesting"
  spec.version      = "1.13.0"
  spec.summary      = "Delightful Swift snapshot testing."

  spec.description  = <<-DESC
  Fork of Point Free Co's Swift Snapshot Testing.
  Once installed, no additional configuration is required. You can import the SnapshotTesting module and call the assertSnapshot function.
                   DESC

  spec.homepage     = "https://github.com/copilotmoney/swift-snapshot-testing"
  spec.license      = "MIT"
 
  spec.authors      = { 
                      "Stephen Celis": "stephen@stephencelis.com",
                      "Brandon Williams": "mbw234@gmail.com"
                      }

  spec.ios.deployment_target = "15.0"
  spec.osx.deployment_target = "12.0"
  spec.source       = { :git => "https://github.com/copilotmoney/swift-snapshot-testing.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources", "Sources/**/*.swift"
  spec.framework  = "XCTest"
  spec.xcconfig = { "ENABLE_BITCODE": "NO" }

end
