import Foundation

extension ProcessInfo {

    static var artifactsDirectory: URL {
        let env = ProcessInfo.processInfo.environment

        return URL(
            fileURLWithPath: env["SNAPSHOT_ARTIFACTS"] ?? NSTemporaryDirectory(),
            isDirectory: true
        )
    }

    static var isXcode: Bool {
        ProcessInfo.processInfo.environment.keys.contains(
            "__XCODE_BUILT_PRODUCTS_DIR_PATHS"
        )
    }
}
