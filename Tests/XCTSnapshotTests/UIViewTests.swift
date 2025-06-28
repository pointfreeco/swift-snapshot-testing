import XCTest

@testable import XCTSnapshot

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
@MainActor
class UIViewTests: XCTestCase {

    override func invokeTest() {
        withTestingEnvironment {
            $0.includeMajorPlatformVersionInPath = true
        } operation: {
            super.invokeTest()
        }
    }

    func testLabel() async throws {
        let label = UILabel()
        label.text = "Hello World"
        label.backgroundColor = .white
        label.textColor = .black
        try await assert(of: label, as: .image)
    }

    func testScrollViewFixedSize() async throws {
        let scrollView = UIScrollView()
        let contentView = UIView()
        let rectangleView = UIView()

        rectangleView.backgroundColor = .red

        contentView.translatesAutoresizingMaskIntoConstraints = false
        rectangleView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.addSubview(rectangleView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor
            ),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        NSLayoutConstraint.activate([
            rectangleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            rectangleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            rectangleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rectangleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rectangleView.heightAnchor.constraint(equalToConstant: 200),
        ])

        try await assert(
            of: scrollView,
            as: .image(layout: .fixed(width: 400, height: 400))
        )
    }

    func testLabelWithDelay() async throws {
        let label = UILabel()
        label.text = "Hello World"
        label.backgroundColor = .white
        label.textColor = .black

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            label.text = "Other text"
        }

        try await assert(
            of: label,
            as: .image(delay: 4)
        )
    }

    func testConstrainedRectangle() async throws {
        let view = UIView()
        view.backgroundColor = .blue
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 200),
            view.widthAnchor.constraint(equalToConstant: 600),
        ])

        try await assert(of: view, as: .image)
    }

    func testConstrainedRectangleWithDelay() async throws {
        let view = UIView()
        view.backgroundColor = .blue

        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 200)
        let widthConstraint = view.widthAnchor.constraint(equalToConstant: 600)

        NSLayoutConstraint.activate([
            heightConstraint,
            widthConstraint,
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            heightConstraint.constant *= 1.5
            widthConstraint.constant *= 1.5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            heightConstraint.constant /= 2
            widthConstraint.constant /= 2
        }

        try await assert(of: view, as: .image(delay: 6))
    }

    func testViewWithSafeArea() async throws {
        let view = UIView()
        view.backgroundColor = .red
        let contentView = UIView()
        contentView.backgroundColor = .blue

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])

        try await assert(
            of: view,
            as: .image(layout: .device(.iPhone16Pro))
        )
    }

    func testViewWithSizeTooBig() async throws {
        let view = UIView()
        view.backgroundColor = .cyan
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 3_000),
            view.widthAnchor.constraint(equalToConstant: 2_000),
        ])

        try await assert(of: view, as: .image)
    }

    func testCustomUserInterfaceStyle() async throws {
        let view = UIView()
        #if os(tvOS)
        view.backgroundColor = .systemGray
        #else
        view.backgroundColor = .systemBackground
        #endif

        try await withTestingEnvironment {
            $0.disableInconsistentTraitsChecker = true
        } operation: {
            try await assert(
                of: view,
                as: .image(traits: .init(userInterfaceStyle: .light)),
                named: "lightMode"
            )

            try await assert(
                of: view,
                as: .image(traits: .init(userInterfaceStyle: .dark)),
                named: "darkMode"
            )
        }
    }

    func testCustomContentSizeCategory() async throws {
        let label = UILabel()
        label.text = "Hello World"
        label.backgroundColor = .white
        label.textColor = .black
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true

        try await withTestingEnvironment {
            $0.disableInconsistentTraitsChecker = true
        } operation: {
            try await assert(
                of: label,
                as: .image(traits: .init(preferredContentSizeCategory: .extraSmall)),
                named: "extraSmall"
            )

            try await assert(
                of: label,
                as: .image(traits: .init(preferredContentSizeCategory: .large)),
                named: "large"
            )

            try await assert(
                of: label,
                as: .image(
                    traits: .init(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
                ),
                named: "accessibilityExtraExtraExtraLarge"
            )
        }
    }

    func testHierarchyAndSimulatedDevice() async throws {
        let view = UIView()
        let subview = UIView()

        view.backgroundColor = .red
        subview.backgroundColor = .blue

        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subview)

        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            subview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            subview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])

        try await assert(
            of: view,
            as: .image(
                sessionRole: .windowApplication,
                layout: .device(.iPhone16Pro)
            ),
            named: "iPhone16Pro"
        )

        try await assert(
            of: view,
            as: .image(layout: .device(.iPhone16Pro)),
            named: "iPhone16Pro"
        )
    }

    func testViewWithSafeAreaConcurrently() async throws {
        let view = UIView()
        view.backgroundColor = .red
        let contentView = UIView()
        contentView.backgroundColor = .blue

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await assert(
                    of: view,
                    as: .image(
                        layout: .device(.iPhone16Pro),
                        delay: 1
                    ),
                    named: "1"
                )
            }

            group.addTask {
                try await assert(
                    of: view,
                    as: .image(
                        layout: .device(.iPhone16Pro),
                        delay: 2
                    ),
                    named: "1"
                )
            }

            for try await _ in group {}
        }
    }
}
#endif
