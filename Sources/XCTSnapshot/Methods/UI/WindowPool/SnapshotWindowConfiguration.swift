#if os(macOS) || os(iOS) || os(tvOS) || os(visionOS)
@MainActor
struct SnapshotWindowConfiguration<Input> {
    let window: SDKWindow
    let input: Input
}
#endif
