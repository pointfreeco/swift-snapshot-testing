import SnapshotTesting

@testable import XCSnapshotTesting

#if canImport(Testing)
import Testing

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

typealias SDKView = UIView
typealias SDKLabel = UILabel
typealias SDKScrollView = UIScrollView
#elseif os(macOS)
import AppKit

typealias SDKView = NSView
typealias SDKLabel = NSText
typealias SDKScrollView = NSScrollView
#endif

#if os(iOS) || os(tvOS) || os(visionOS) || os(macOS)
@MainActor
struct UITests {

    // MARK: - Base Configuration
    private func setupViewWithSafeArea() -> SDKView {
        let view = SDKView()
        let contentView = SDKView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])

        return view
    }

    #if !os(macOS)
    @Test
    func basicElements() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                let label: SDKLabel = await MainActor.run {
                    let label = SDKLabel()
                    #if os(macOS)
                    label.string = "Hello World"
                    #else
                    label.text = "Hello World"
                    #endif
                    label.backgroundColor = .white
                    label.textColor = .black
                    return label
                }

                try await assert(of: label, as: .image)
            }

            group.addTask {
                let scrollView: SDKScrollView = await MainActor.run {
                    let scrollView = SDKScrollView()
                    let contentView = SDKView()
                    let rectangleView = SDKView()

                    rectangleView.backgroundColor = .red

                    contentView.translatesAutoresizingMaskIntoConstraints = false
                    rectangleView.translatesAutoresizingMaskIntoConstraints = false

                    scrollView.addSubview(contentView)
                    contentView.addSubview(rectangleView)

                    NSLayoutConstraint.activate([
                        contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                        contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                        contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                        contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                        contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
                    ])

                    NSLayoutConstraint.activate([
                        rectangleView.topAnchor.constraint(equalTo: contentView.topAnchor),
                        rectangleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                        rectangleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                        rectangleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                        rectangleView.heightAnchor.constraint(equalToConstant: 200),
                    ])

                    return scrollView
                }

                try await assert(of: scrollView, as: .image(layout: .fixed(width: 400, height: 400)))
            }

            for try await _ in group {}
        }
    }
    #endif

    @Test
    func dynamicUpdates() async throws {
        let view = SDKView()

        let constraint = view.widthAnchor.constraint(equalToConstant: 600)

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 300),
            constraint,
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            constraint.constant *= 1.5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            constraint.constant /= 2
        }

        try await assert(of: view, as: .image(delay: 6))
    }

    #if !os(macOS)
    @Test
    func uiTraits() async throws {
        try await withTestingEnvironment {
            $0.disableInconsistentTraitsChecker = true
        } operation: {
            let view = SDKView()
            #if os(visionOS)
            view.backgroundColor = .init(dynamicProvider: {
                if $0.userInterfaceStyle == .light {
                    return .red
                } else {
                    return .blue
                }
            })
            #elseif !os(tvOS)
            view.backgroundColor = .systemBackground
            #else
            view.backgroundColor = .systemGray
            #endif

            let testCases = [
                (UIUserInterfaceStyle.light, "lightMode"),
                (.dark, "darkMode"),
            ]

            for (style, name) in testCases {
                try await assert(
                    of: view,
                    as: .image(traits: .init(userInterfaceStyle: style)),
                    named: name
                )
            }
        }
    }

    @Test
    func accessibilityAndContentSize() async throws {
        let label = SDKLabel()
        label.text = "Hello World"
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true

        let categories: [UIContentSizeCategory] = [
            .extraSmall,
            .large,
            .accessibilityExtraExtraExtraLarge,
        ]

        try await withTestingEnvironment {
            $0.disableInconsistentTraitsChecker = true
        } operation: {
            for category in categories {
                try await assert(
                    of: label,
                    as: .image(traits: .init(preferredContentSizeCategory: category)),
                    named: category.rawValue
                )
            }
        }
    }

    @Test
    func deviceSpecificLayouts() async throws {
        let view = setupViewWithSafeArea()
        view.backgroundColor = .red

        try await assert(
            of: view,
            as: .image(layout: .device(.iPhone16Pro)),
            named: "iPhone16Pro"
        )
    }
    #endif

    @Test
    func complexLayouts() async throws {
        let bigView = SDKView()
        #if os(macOS)
        bigView.wantsLayer = true
        bigView.layer?.backgroundColor = NSColor.cyan.cgColor
        #else
        bigView.backgroundColor = .cyan
        #endif
        NSLayoutConstraint.activate([
            bigView.heightAnchor.constraint(equalToConstant: 3000),
            bigView.widthAnchor.constraint(equalToConstant: 2000),
        ])

        try await assert(of: bigView, as: .image)
    }

    #if !os(macOS)
    @Test
    func concurrentUpdates() async throws {
        let view = setupViewWithSafeArea()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await assert(
                    of: view,
                    as: .image(layout: .device(.iPhone16Pro), delay: 1),
                    named: "1"
                )
            }
            group.addTask {
                try await assert(
                    of: view,
                    as: .image(layout: .device(.iPhone16Pro), delay: 2),
                    named: "2"
                )
            }

            for try await _ in group {}
        }
    }
    #endif
}
#endif
#endif
