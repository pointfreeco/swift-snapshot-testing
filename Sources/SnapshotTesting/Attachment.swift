import XCTest

public struct Attachment {
  #if Xcode
  internal let rawValue: XCTAttachment
  #endif

  init(string: String, name: String? = nil, uniformTypeIdentifier: String? = nil) {
    #if Xcode
    if let uniformTypeIdentifier = uniformTypeIdentifier {
      self.rawValue = XCTAttachment(data: Data(string.utf8), uniformTypeIdentifier: uniformTypeIdentifier)
    } else {
      self.rawValue = XCTAttachment(string: string)
    }
    self.rawValue.name = name
    #endif
  }
}
