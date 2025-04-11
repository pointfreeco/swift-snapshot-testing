import Foundation

/// A wrapper around an asynchronous operation.
///
/// Snapshot strategies may utilize this type to create snapshots in an asynchronous fashion.
///
/// For example, WebKit's `WKWebView` offers a callback-based API for taking image snapshots
/// (`takeSnapshot`). `Async` allows us to build a value that can pass its callback along to the
/// scope in which the image has been created.
///
/// ```swift
/// Async<UIImage> { callback in
///   webView.takeSnapshot(with: nil) { image, error in
///     callback(image!)
///   }
/// }
/// ```
public struct Async<Value> {
  public let run: (@escaping (Value) -> Void) -> Void

  /// Creates an asynchronous operation.
  ///
  /// - Parameters:
  ///   - run: A function that, when called, can hand a value to a callback.
  public init(run: @escaping (_ callback: @escaping (Value) -> Void) -> Void) {
    self.run = run
  }

  /// Wraps a pure value in an asynchronous operation.
  ///
  /// - Parameter value: A value to be wrapped in an asynchronous operation.
  public init(value: Value) {
    self.init { callback in callback(value) }
  }

  /// Transforms an `Async<Value>` into an `Async<NewValue>` with a function `(Value) -> NewValue`.
  ///
  /// - Parameter transform: A transformation to apply to the value wrapped by the async value.
  public func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Async<NewValue> {
    .init { callback in
      self.run { value in callback(transform(value)) }
    }
  }

  /// Delays the completion of this asynchronous operation by a specified time interval.
  ///
  /// This method returns a new `Async<Value>` that, when executed, waits for the original asynchronous operation to complete,
  /// then delays the delivery of its result by the specified interval before invoking the callback. If the `timeInterval` is `nil`,
  /// the original `Async<Value>` is returned without any delay.
  ///
  /// - Parameter timeInterval: The time interval (in seconds) to delay the result delivery after the original operation completes.
  /// A `nil` value skips the delay.
  /// - Returns: A new `Async<Value>` instance with the delayed result delivery.
  func delay(by timeInterval: Double?) -> Async<Value> {
    guard let timeInterval = timeInterval else {
      return self
    }

    return .init { callback in
      self.run { value in
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
          callback(value)
        }
      }
    }
  }
}
