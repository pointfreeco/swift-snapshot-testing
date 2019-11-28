import Foundation
import XCTest

/// Creates a new test activity. If the test has failed, all attachments will be added. If the test has passed, attachments are only added if `attachReferenceImages` is true.
///
/// - Parameters:
///   - result: The result to pull the artifacts and pass status from.
///   - name: A unique name for the test which is, if available, appeneded to the activity name
///   - attachReferenceImages: If enabled, reference data will always be added irrespective of whether the test passes or fails.
func addTestArtifacts(
  from result: Result<[XCTAttachment]?, FailureError>,
  named name: String? = nil,
  attachReferenceImages: Bool = false
) {
  #if !os(Linux)
    guard ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") else {
      return
    }
    var message = "Attached " + (result.isSuccessful ? "Reference" : "Failure Diff")
    if let name = name {
      message += " - \(name)"
    }
    XCTContext.runActivity(named: message) { activity in
      result.attachments.forEach {
        if result.isSuccessful, attachReferenceImages {
          // If the diff passed, and attachReferenceImages is enabled, then add attachment
          $0.lifetime = .keepAlways
          activity.add($0)
        } else if !result.isSuccessful {
          // If the diff failed, then add attachment
          activity.add($0)
        }
      }
    }
  #endif
}

