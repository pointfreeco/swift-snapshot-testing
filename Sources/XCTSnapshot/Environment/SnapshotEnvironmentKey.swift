import Foundation

public protocol SnapshotEnvironmentKey {
  associatedtype Value: Sendable

  static var defaultValue: Value { get }
}
