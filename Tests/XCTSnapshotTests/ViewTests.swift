import SwiftUI
import XCTSnapshot
import XCTest

#if !os(watchOS)
@MainActor
class ViewTests: XCTestCase {

    override func invokeTest() {
        withTestingEnvironment {
            $0.includeMajorPlatformVersionInPath = true
        } operation: {
            super.invokeTest()
        }
    }

    func testLabel() async throws {
        struct TestingView: View {
            var body: some View {
                Text("Hello World")
                    .foregroundColor(.black)
                    .background(Color.white)
            }
        }

        try await assert(of: TestingView(), as: .image)
    }

    func testScrollView() async throws {
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

    func testLabelWithDelay() async throws {
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

    func testFramedRectangle() async throws {
        struct TestingView: View {
            var body: some View {
                Rectangle()
                    .fill(.blue)
                    .frame(width: 600, height: 200)
            }
        }

        try await assert(of: TestingView(), as: .image)
    }

    func testFramedRectangleWithDelay() async throws {
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

    #if !os(macOS)
    func testViewWithSafeArea() async throws {
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
    #endif

    func testViewWithSizeTooBig() async throws {
        struct TestingView: View {
            var body: some View {
                Rectangle()
                    .fill(.green)
                    .frame(width: 2_000, height: 3_000)
            }
        }

        try await assert(of: TestingView(), as: .image)
    }

    #if !os(macOS)
    func testCustomUserInterfaceStyle() async throws {
        struct TestingView: View {
            var body: some View {
                Rectangle()
                    #if os(tvOS)
                .fill(Color(UIColor.systemGray))
                    #else
                .fill(Color(UIColor.systemBackground))
                    #endif
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

    func testCustomContentSizeCategory() async throws {
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
                traits: .init(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
            ),
            named: "accessibilityExtraExtraExtraLarge"
        )
    }

    func testHierarchyAndSimulatedDevice() async throws {
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

    func testComplexSateManagementUpdateWithNavigationController() async throws {
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
}
#endif
