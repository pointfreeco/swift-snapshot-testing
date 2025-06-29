#if os(Linux) || os(Android) || os(Windows)
  import Foundation

  @available(*, deprecated, message: "Not available anymore")
  public struct XCTAttachment {
    public init(data: Data) {}
    public init(data: Data, uniformTypeIdentifier: String) {}
  }
#endif
