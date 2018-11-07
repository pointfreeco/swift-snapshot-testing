@testable import SnapshotTesting
import XCTest

#if os(iOS)
let platform = "ios"
#elseif os(macOS)
let platform = "macos"
extension NSTextField {
  var text: String {
    get { return self.stringValue }
    set { self.stringValue = newValue }
  }
}
#endif
