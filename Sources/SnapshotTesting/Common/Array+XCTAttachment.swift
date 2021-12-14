import XCTest

extension Array where Element == XCTAttachment {
  /// Create a new `XCTContext` activity with `name` and add the attachments.
  func addAttachments(toActivityNamed name: String) {
    guard !isEmpty else { return }

    #if !os(Linux)
    let shouldRunActivityToAddAttachments = (
      ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") ||
      ProcessInfo.processInfo.environment.keys.contains("SNAPSHOT_TESTING_WRITE_ATTACHMENTS")
    )

    if shouldRunActivityToAddAttachments {
      XCTContext.runActivity(named: "Attached Failure Diff") { activity in
        forEach {
          activity.add($0)
        }
      }
    }
    #endif
  }
}
