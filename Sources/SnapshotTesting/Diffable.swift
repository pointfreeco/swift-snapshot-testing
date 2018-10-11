import Foundation

public struct Diffable<A> {
  public let to: (A) -> Data?
  public let fro: (Data) -> A?
  public let diff: (A, A) -> (String, [Attachment])?

  public init(
    to: @escaping (A) -> Data?,
    fro: @escaping (Data) -> A?,
    diff: @escaping (A, A) -> (String, [Attachment])?
    ) {
    self.to = to
    self.fro = fro
    self.diff = diff
  }
}
