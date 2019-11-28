import Foundation
import XCTest

public struct FailureError: LocalizedError {
  
  /// The reason in which the test failed
  let reason: String
  
  /// The artifacts describing the failure
  let artifacts: [XCTAttachment]
  
  // MARK: LocalizedError
  
  public var errorDescription: String? {
    return reason
  }
  
}

extension Result where Failure == FailureError {
  var error: String? {
    switch self {
    case .failure(let error):
      return error.reason
    case .success:
      return nil
    }
  }
}

extension Result where Failure == FailureError, Success == [XCTAttachment]? {
  var attachments: [XCTAttachment] {
    switch self {
    case .failure(let error):
      return error.artifacts
    case .success(let artifacts):
      return artifacts ?? []
    }
  }
  
  var isSuccessful: Bool {
    if case .success = self {
      return true
    }
    return false
  }
}
