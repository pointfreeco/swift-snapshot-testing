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
@available(*, deprecated)
public struct Async<Value> {
  private let _run: () async -> Value

  /// Creates an asynchronous operation.
  ///
  /// - Parameters:
  ///   - run: A function that, when called, can hand a value to a callback.
  public init(run: @escaping () async -> Value) {
    self._run = run
  }

  /// Creates an asynchronous operation.
  ///
  /// - Parameters:
  ///   - run: A function that, when called, can hand a value to a callback.
  ///   - callback: A function that can be called with a value.
  public init(run: @escaping (_ callback: @escaping (Value) -> Void) -> Void) {
    self.init {
      await withUnsafeContinuation { continuation in
        run(continuation.resume(returning:))
      }
    }
  }

  /// Wraps a pure value in an asynchronous operation.
  ///
  /// - Parameter value: A value to be wrapped in an asynchronous operation.
  public init(value: Value) {
    self.init { callback in callback(value) }
  }

  public func run() async -> Value {
    await self._run()
  }

  public func run(_ callback: @escaping (Value) -> Void) {
    Task {
      await callback(self.run())
    }
  }

  /// Transforms an Async<Value> into an Async<NewValue> with a function `(Value) -> NewValue`.
  ///
  /// - Parameter f: A transformation to apply to the value wrapped by the async value.
  public func map<NewValue>(_ f: @escaping (Value) -> NewValue) -> Async<NewValue> {
    return .init {
      await f(self.run())
    }
  }
}
