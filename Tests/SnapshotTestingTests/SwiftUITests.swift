#if compiler(>=6) && canImport(Testing) && canImport(SwiftUI)
  import Testing
  import SnapshotTesting
  import SwiftUI

/// you can use `NSScreen.main?.backingScaleFactor` or `UIScreen.main.scale` but for more consistent results a fixed value is choosen
let scaleFactor: CGFloat = 4

private struct TestView: View {
  var body: some View {
    ZStack {
      Color.white
      Text("Hello world")
    }
    .frame(width: 120)
  }
}

#if canImport(AppKit)
import AppKit

@MainActor @Test func simpleSwiftUIViewAllPlatforms() async throws {
  let renderer = ImageRenderer(content: TestView())
  renderer.scale = scaleFactor

  // Note there is an issue with blurred images https://github.com/pointfreeco/swift-snapshot-testing/issues/428
  // but here the scaleFactor is chosen large so it is nearly not visible.
  let nsImage = try #require(renderer.nsImage)
  assertSnapshot(of: nsImage, as: .image, named: "appkit")
}
#elseif canImport(UIKit)
@available(iOS 16.0, tvOS 16.0, *)
@MainActor @Test func simpleSwiftUIViewAllPlatforms() async throws {
  let renderer = ImageRenderer(content: TestView())
  renderer.scale = scaleFactor

  let nsImage = try #require(renderer.uiImage)
  assertSnapshot(of: nsImage, as: .image, named: "uikit")
}
#endif
#endif
