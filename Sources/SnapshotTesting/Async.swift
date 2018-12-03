public enum Async<Value> {
  case pure(Value)
  case delayed((@escaping (Value) -> Void) -> Void)

  public var run: (@escaping (Value) -> Void) -> Void {
    return { callback in
      switch self {
      case let .pure(value):
        callback(value)
      case let .delayed(runner):
        runner(callback)
      }
    }
  }

  public init(run: @escaping (_ callback: @escaping (Value) -> Void) -> Void) {
    self = .delayed(run)
  }

  public init(value: Value) {
    self = .pure(value)
  }

  public func map<NewValue>(_ f: @escaping (Value) -> NewValue) -> Async<NewValue> {
    return Async<NewValue> { callback in
      self.run { a in
        callback(f(a))
      }
    }
  }
}

/// A wrapper around an asynchronous operation.
///
/// Snapshot strategies may utilize this type to create snapshots in an asynchronous fashion.
///
/// For example, WebKit's `WKWebView` offers a callback-based API for taking image snapshots (`takeSnapshot`). `Async` allows us to build a value that can pass its callback along to the scope in which the image has been created.
///
///     Async<UIImage> { callback in
///       webView.takeSnapshot(with: nil) { image, error in
///         callback(image!)
///       }
///     }
//public struct Async<Value> {
//  public let run: (@escaping (Value) -> Void) -> Void
//
//  /// Creates an asynchronous operation.
//  ///
//  /// - Parameters:
//  ///   - run: A function that, when called, can hand a value to a callback.
//  ///   - callback: A function that can be called with a value.
//  public init(run: @escaping (_ callback: @escaping (Value) -> Void) -> Void) {
//    self.run = run
//  }
//
//  /// Wraps a pure value in an asynchronous operation.
//  ///
//  /// - Parameter value: A value to be wrapped in an asynchronous operation.
//  public init(value: Value) {
//    self.init { callback in callback(value) }
//  }
//
//  public func map<NewValue>(_ f: @escaping (Value) -> NewValue) -> Async<NewValue> {
//    return Async<NewValue> { callback in
//      self.run { a in
//        callback(f(a))
//      }
//    }
//  }
//}
