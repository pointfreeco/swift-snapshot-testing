import XCTest

@testable import SnapshotTesting

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
#if canImport(SceneKit)
  import SceneKit
#endif
#if canImport(SpriteKit)
  import SpriteKit
  import SwiftUI
#endif
#if canImport(WebKit)
  @preconcurrency import WebKit
#endif
#if canImport(UIKit)
  import UIKit.UIView
#endif

class ImageDelayTests: BaseTestCase {

  func testView() {
    #if os(iOS) || os(tvOS)
    class LabelValueView: UILabel {

      override func didMoveToWindow() {
        super.didMoveToWindow()
        updateValue(.zero)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.updateValue(1)
        }
      }

      func updateValue(_ value: Int) {
        text = "Current value: \(value)"
      }
    }
    if !ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW") {
      assertSnapshot(
        of: LabelValueView(),
        as: .image(size: .init(width: 200, height: 100)),
        named: platform + "-0"
      )
      assertSnapshot(
        of: LabelValueView(),
        as: .image(size: .init(width: 200, height: 100), delay: 4),
        named: platform + "-1"
      )
    }
    #endif
  }

  func testUIViewController() {
    #if os(iOS) || os(tvOS)
    class ValueViewController: UIViewController {

      var label = UILabel()

      override func viewDidLoad() {
        super.viewDidLoad()
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
          label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
          label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        label.text = "Current value: 0"
      }

      override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.label.text = "Current value: 1"
        }
      }
    }
    assertSnapshot(
      of: ValueViewController(),
      as: .image(size: .init(width: 200.0, height: 100.0)),
      named: platform + "-0"
    )
    assertSnapshot(
      of: ValueViewController(),
      as: .image(size: .init(width: 200.0, height: 100.0), delay: 4),
      named: platform + "-1"
    )
    #endif
  }

  func testSwiftUIView() {
    #if os(iOS) || os(tvOS)
    struct LabelValue: SwiftUI.View {
      @State var value: Int = 0

      var body: some SwiftUI.View {
        Text("Current value: \(value)")
          .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              value = 1
            }
          }
      }
    }
    assertSnapshot(
      of: LabelValue(),
      as: .image(layout: .fixed(width: 200.0, height: 100.0)),
      named: platform + "-0"
    )
    assertSnapshot(
      of: LabelValue(),
      as: .image(layout: .fixed(width: 200.0, height: 100.0), delay: 4),
      named: platform + "-1"
    )
    #endif
  }
}
