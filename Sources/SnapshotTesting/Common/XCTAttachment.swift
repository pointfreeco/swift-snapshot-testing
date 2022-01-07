#if os(Linux) || os(Windows)
import Foundation

public struct XCTAttachment {
  public init(data: Data) {}
  public init(data: Data, uniformTypeIdentifier: String) {}
}
#endif
