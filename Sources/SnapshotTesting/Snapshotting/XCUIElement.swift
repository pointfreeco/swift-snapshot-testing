import Foundation
import XCTest

#if os(iOS)
extension Snapshotting where Value == XCUIElement, Format == String {
  /// A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.
  public static let recursiveDescription: Snapshotting = SimplySnapshotting.lines.pullback { element in
    return element.subtree()
  }
}


extension XCUIElementSnapshot {
  func subtree(prefix: String = "") -> String {
    var result = prefix + "\(self)\n"
    
    for child in children {
      result += child.subtree(prefix: " " + prefix)
    }
    
    return result
  }
}

extension XCUIElement {
  func subtree() -> String {
    guard let snapshot = try? self.snapshot() else { return "" }
    
    return snapshot.subtree()
  }
}
#endif
