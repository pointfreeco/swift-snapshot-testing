import SnapshotTesting
import SwiftUI
import Testing

@MainActor
struct ViewTests {

  @Test
  func label() async throws {
    guard #available(watchOS 9.0, *) else {
      return
    }

    struct TestingView: View {
      var body: some View {
        Text("Hello World")
          .foregroundColor(.black)
          .background(Color.white)
      }
    }

    try await assert(of: TestingView(), as: .image)
  }

  @Test
  func scrollView() async throws {
    guard #available(watchOS 9.0, *) else {
      return
    }

    struct TestingView: View {
      var body: some View {
        ScrollView {
          Rectangle()
            .fill(.red)
            .frame(height: 200)
        }
      }
    }

    try await assert(
      of: TestingView(),
      as: .image(layout: .fixed(width: 400, height: 400))
    )
  }

  #if !os(watchOS)
    @Test
    func labelWithDelay() async throws {
      guard #available(watchOS 9.0, *) else {
        return
      }

      struct TestingView: View {
        @State var text = "Hello World"

        var body: some View {
          Text(text)
            .foregroundColor(.black)
            .background(Color.white)
            .onAppear {
              DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                text = "Other text"
              }
            }
        }
      }

      try await assert(of: TestingView(), as: .image(delay: 4))
    }
  #endif

  @Test
  func framedRectangle() async throws {
    guard #available(watchOS 9.0, *) else {
      return
    }

    struct TestingView: View {
      var body: some View {
        Rectangle()
          .fill(.blue)
          .frame(width: 600, height: 200)
      }
    }

    try await assert(of: TestingView(), as: .image)
  }

  #if !os(watchOS)
    @Test
    func framedRectangleWithDelay() async throws {
      struct TestingView: View {
        @State var size: CGSize = .init(width: 600, height: 200)

        var body: some View {
          Rectangle()
            .fill(.blue)
            .frame(width: size.width, height: size.height)
            .onAppear {
              DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                size.height *= 1.5
                size.width *= 1.5
              }

              DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                size.height /= 2
                size.width /= 2
              }
            }
        }
      }

      try await assert(of: TestingView(), as: .image(delay: 6))
    }
  #endif

  #if os(iOS) || os(tvOS)
    @Test
    func viewWithSafeArea() async throws {
      struct TestingView: View {
        var body: some View {
          ZStack {
            Rectangle()
              .fill(.red)
              .edgesIgnoringSafeArea(.all)

            Rectangle()
              .fill(.blue)
          }
        }
      }

      try await assert(
        of: TestingView(),
        as: .image(layout: .device(.iPhone16Pro))
      )
    }

    @Test
    func viewInKeyWindow() async throws {
      struct TestingView: View {
        var body: some View {
          Rectangle()
            .fill(.yellow)
            .edgesIgnoringSafeArea(.all)
        }
      }

      try await assert(
        of: TestingView(),
        as: .image(
          sessionRole: .windowApplication,
          layout: .device(.iPhone16Pro)
        )
      )
    }

    @Test
    func viewInKeyWindowWithSafeArea() async throws {
      struct TestingView: View {
        var body: some View {
          ZStack {
            Rectangle()
              .fill(.red)
              .edgesIgnoringSafeArea(.all)

            Rectangle()
              .fill(.blue)

          }
        }
      }

      try await assert(
        of: TestingView(),
        as: .image(
          sessionRole: .windowApplication,
          layout: .device(.iPhone16Pro)
        )
      )
    }
  #endif

  #if !os(watchOS) && !os(macOS)
    @Test
    func viewInKeyWindowWithFixedSize() async throws {
      struct TestingView: View {
        var body: some View {
          Rectangle()
            .fill(.yellow)
        }
      }

      try await assert(
        of: TestingView(),
        as: .image(
          sessionRole: .windowApplication,
          layout: .fixed(width: 300, height: 150)
        )
      )
    }

    @Test
    func viewWithSizeTooBig() async throws {
      struct TestingView: View {
        var body: some View {
          Rectangle()
            .fill(.green)
            .frame(width: 2_000, height: 3_000)
        }
      }

      try await assert(of: TestingView(), as: .image)
    }

    #if os(iOS) || os(tvOS)
      @Test
      func customUserInterfaceStyle() async throws {
        struct TestingView: View {
          var body: some View {
            Rectangle()
              .fill(Color(UIColor.systemBackground))
              .edgesIgnoringSafeArea(.all)
          }
        }

        try await assert(
          of: TestingView(),
          as: .image(
            layout: .device(.iPhone16Pro),
            traits: .init(userInterfaceStyle: .light)
          ),
          named: "lightMode"
        )

        try await assert(
          of: TestingView(),
          as: .image(
            layout: .device(.iPhone16Pro),
            traits: .init(userInterfaceStyle: .dark)
          ),
          named: "darkMode"
        )
      }

      @Test
      func customContentSizeCategory() async throws {
        struct TestingView: View {
          var body: some View {
            Text("Hello World")
              .foregroundColor(.black)
              .font(.body)
          }
        }

        try await assert(
          of: TestingView(),
          as: .image(traits: .init(preferredContentSizeCategory: .extraSmall)),
          named: "extraSmall"
        )

        try await assert(
          of: TestingView(),
          as: .image(traits: .init(preferredContentSizeCategory: .large)),
          named: "large"
        )

        try await assert(
          of: TestingView(),
          as: .image(
            traits: .init(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)),
          named: "accessibilityExtraExtraExtraLarge"
        )
      }

      @Test
      func hierarchyAndSimulatedDevice() async throws {
        struct TestingView: View {
          var body: some View {
            ZStack {
              Rectangle()
                .fill(.red)
                .edgesIgnoringSafeArea(.all)

              Rectangle()
                .fill(.blue)

            }
          }
        }

        try await assert(
          of: TestingView(),
          as: .image(
            sessionRole: .windowApplication,
            layout: .device(.iPhone16Pro)
          ),
          named: "iPhone16Pro"
        )

        try await assert(
          of: TestingView(),
          as: .image(layout: .device(.iPhone16Pro)),
          named: "iPhone16Pro"
        )
      }

      @Test
      func complexSateManagementUpdateWithNavigationController() async throws {
        struct TestingView: View {
          @ObservedObject var viewModel: ViewModel

          var body: some View {
            Text(viewModel.text)
              .foregroundColor(.black)
              .font(.body)
              .onAppear {
                viewModel.didAppear()
              }
          }
        }

        @MainActor
        class ViewModel: ObservableObject {

          @Published var text = "Hello World"

          func didAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              self.text = "Other text"
            }
          }
        }

        let viewModel = ViewModel()

        try await assert(
          of: await UINavigationController(
            rootViewController: UIHostingController(
              rootView: TestingView(
                viewModel: viewModel
              )
            )
          ),
          as: .image(delay: 4)
        )
      }
    #endif
  #endif
}
