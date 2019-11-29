#if os(Linux)
import Foundation

public class XCTAttachment {
  public init(data: Data) {}
  public init(data: Data, uniformTypeIdentifier: String) {}
  var name: String?
}
#endif
