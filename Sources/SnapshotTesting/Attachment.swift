import XCTest

/// A wrapper around XCTest's attachment API for Linux compatibility.
public struct Attachment {
  #if !os(Linux)
  internal let rawValue: XCTAttachment
  #endif

  init(data: Data, name: String? = nil, uniformTypeIdentifier: String? = nil) {
    #if !os(Linux)
    if let uniformTypeIdentifier = uniformTypeIdentifier {
      self.rawValue = XCTAttachment(data: data, uniformTypeIdentifier: uniformTypeIdentifier)
    } else {
      self.rawValue = XCTAttachment(data: data)
    }
    self.rawValue.name = name
    #endif
  }

  init(string: String, name: String? = nil, uniformTypeIdentifier: String? = nil) {
    #if !os(Linux)
    self.init(data: Data(string.utf8), name: name, uniformTypeIdentifier: uniformTypeIdentifier)
    #endif
  }
}
