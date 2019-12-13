@testable import SnapshotTesting
import XCTest

#if os(iOS)
#if targetEnvironment(macCatalyst)
let platform = "maccatalyst"
#else
let platform = "ios"
#endif
#elseif os(tvOS)
let platform = "tvos"
#elseif os(macOS)
let platform = "macos"
extension NSTextField {
  var text: String {
    get { return self.stringValue }
    set { self.stringValue = newValue }
  }
}
#endif
