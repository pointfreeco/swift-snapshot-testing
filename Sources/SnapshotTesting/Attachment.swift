import XCTest

public struct Attachment {
  #if Xcode
  internal let rawValue: XCTAttachment
  #endif

  init(string: String, name: String? = nil) {
    #if Xcode
    self.rawValue = XCTAttachment(string: string)
    self.rawValue.name = name
    #endif
  }
}
