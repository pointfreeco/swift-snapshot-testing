#if canImport(Foundation)
import Foundation
@objc
public protocol SnapshotTestingPlugin {
  static var identifier: String { get }
  init()
}
#endif
