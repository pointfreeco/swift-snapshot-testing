public struct Async<A> {
  public let run: (@escaping (A) -> Void) -> Void

  public init(run: @escaping (@escaping (A) -> Void) -> Void) {
    self.run = run
  }

  public init(value: A) {
    self.init { callback in callback(value) }
  }
}
