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
  var error: (String, [XCTAttachment])? {
    switch self {
    case .failure(let error):
      return (error.reason, error.artifacts)
    case .success:
      return nil
    }
  }
}
