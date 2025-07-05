#if os(iOS) || os(macOS) || os(visionOS)
import WebKit

extension WKWebView {

    func waitLoadingState(tolerance: TimeInterval) async throws {
        repeat {
            try await Task.sleep(nanoseconds: UInt64(tolerance * 1_000_000_000))
        } while isLoading
    }
}
#endif
