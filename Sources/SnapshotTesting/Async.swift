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
public enum Async<Value> {
  case pure(Value)
  case delayed((@escaping (Value) -> Void) -> Void)

  /// Creates an asynchronous operation.
  ///
  /// - Parameters:
  ///   - run: A function that, when called, can hand a value to a callback.
  ///   - callback: A function that can be called with a value.
  public init(run: @escaping (_ callback: @escaping (Value) -> Void) -> Void) {
    self = .delayed(run)
  }

  /// Wraps a pure value in an asynchronous operation.
  ///
  /// - Parameter value: A value to be wrapped in an asynchronous operation.
  public init(value: Value) {
    self = .pure(value)
  }

  public func run(callback: @escaping (Value) -> Void) {
    switch self {
    case let .pure(value):
      callback(value)
    case let .delayed(runner):
      runner(callback)
    }
  }

  public func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Async<NewValue> {
    switch self {
    case let .pure(value):
      return Async<NewValue>(value: transform(value))
    case let .delayed(run):
      return Async<NewValue> { callback in run { value in callback(transform(value)) } }
    }
  }
}

extension Array {
  public func sequence<A>() -> Async<[A]> where Element == Async<A> {
    return self.reduce(Async(value: [])) { axs, ax in
      switch (axs, ax) {
      case let (.pure(xs), .pure(x)):
        return Async(value: xs + [x])
      default:
        return Async { callback in
          axs.run { xs in
            ax.run { x in
              callback(xs + [x])
            }
          }
        }
      }
    }
  }
}
