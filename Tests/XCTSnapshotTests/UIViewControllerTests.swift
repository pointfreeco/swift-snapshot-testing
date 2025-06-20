import XCTSnapshot
import XCTest
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
@preconcurrency import AppKit
#endif

#if os(iOS) || os(tvOS)
@MainActor
class UIViewControllerTests: XCTestCase {

  func testLabel() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let view = UILabel()
        view.text = "Hello World"
        view.backgroundColor = .white
        self.view = view
      }
    }

    try await assert(of: TestingViewController(), as: .image)
  }

  func testScrollView() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let scrollView = UIScrollView()
        let stackView = UIStackView()
        let rectangle = UIView()

        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        rectangle.backgroundColor = .red

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(rectangle)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
          rectangle.heightAnchor.constraint(equalToConstant: 200),

          stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
          stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
          stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
          stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),

          stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        view = scrollView
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image(layout: .fixed(width: 400, height: 400))
    )
  }

  func testLabelWithDelay() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let view = UILabel()
        view.text = "Hello World"
        view.backgroundColor = .white
        view.textColor = .black

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          view.text = "Other text"
        }

        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .horizontal)

        self.view = view
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image(delay: 4)
    )
  }

  func testFramedRectangle() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let view = UIView()
        view.backgroundColor = .blue
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          view.widthAnchor.constraint(equalToConstant: 600),
          view.heightAnchor.constraint(equalToConstant: 200)
        ])

        self.view = view
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image
    )
  }

  func testFramedRectangleWithDelay() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let view = UIView()
        view.backgroundColor = .blue
        view.translatesAutoresizingMaskIntoConstraints = false

        let widthConstraint = view.widthAnchor.constraint(equalToConstant: 600)
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 200)

        NSLayoutConstraint.activate([
          widthConstraint,
          heightConstraint
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          heightConstraint.constant *= 1.5
          widthConstraint.constant *= 1.5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
          heightConstraint.constant /= 2
          widthConstraint.constant /= 2
        }

        self.view = view
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image(delay: 6)
    )
  }

  func testViewWithSafeArea() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
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
        self.view = view
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image(
        layout: .device(.iPhone16Pro)
      )
    )
  }

  func testViewInKeyWindow() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let view = UIView()
        view.backgroundColor = .yellow
        self.view = view
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image(
        drawHierarchyInKeyWindow: true,
        layout: .device(.iPhone16Pro)
      )
    )
  }

  func testViewInKeyWindowWithSafeArea() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let view = UIView()
        let contentView = UIView()

        view.backgroundColor = .red
        contentView.backgroundColor = .blue

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
          contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
          contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
          contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
          contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        self.view = view
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image(
        drawHierarchyInKeyWindow: true,
        layout: .device(.iPhone16Pro)
      )
    )
  }

  func testViewInKeyWindowWithFixedSize() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let view = UIView()
        view.backgroundColor = .yellow
        self.view = view
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image(
        drawHierarchyInKeyWindow: true,
        layout: .fixed(width: 300, height: 150)
      )
    )
  }

  func testViewWithSizeTooBig() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let view = UIView()
        view.backgroundColor = .cyan
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          view.heightAnchor.constraint(equalToConstant: 3_000),
          view.widthAnchor.constraint(equalToConstant: 2_000),
        ])
        self.view = view
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image
    )
  }

  func testCustomUserInterfaceStyle() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let view = UIView()
        view.backgroundColor = .systemBackground
        self.view = view
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image(
        layout: .device(.iPhone16Pro),
        traits: .init(userInterfaceStyle: .light)
      ),
      named: "lightMode"
    )

    try await assert(
      of: TestingViewController(),
      as: .image(
        layout: .device(.iPhone16Pro),
        traits: .init(userInterfaceStyle: .dark)
      ),
      named: "darkMode"
    )
  }

  func testCustomContentSizeCategory() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let label = UILabel()
        label.text = "Hello World"
        label.backgroundColor = .white
        label.textColor = .black
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        self.view = label
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image(traits: .init(preferredContentSizeCategory: .extraSmall)),
      named: "extraSmall"
    )

    try await assert(
      of: TestingViewController(),
      as: .image(traits: .init(preferredContentSizeCategory: .large)),
      named: "large"
    )

    try await assert(
      of: TestingViewController(),
      as: .image(traits: .init(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)),
      named: "accessibilityExtraExtraExtraLarge"
    )
  }

  func testNavigationController() async throws {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .brown
    viewController.navigationItem.title = "Hello World"

    let navigationController = UINavigationController(rootViewController: viewController)

    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.titleTextAttributes = [
      .foregroundColor: UIColor.white
    ]
    appearance.backgroundColor = .green

    navigationController.navigationBar.standardAppearance = appearance
    navigationController.navigationBar.scrollEdgeAppearance = appearance

    try await assert(
      of: navigationController,
      as: .image(
        layout: .device(.iPhone16Pro)
      )
    )
  }

  func testTabBarController() async throws {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .darkGray
    viewController.tabBarItem.title = "Home"
    viewController.tabBarItem.image = .init(systemName: "house")

    let tabBarController = UITabBarController()
    tabBarController.setViewControllers([viewController], animated: false)

    try await assert(
      of: tabBarController,
      as: .image(
        layout: .device(.iPhone16Pro)
      )
    )
  }

  func testTabBarWithNavigationController() async throws {
    // 1. Setup controllers
    let viewController = UIViewController()
    let navigationController = UINavigationController(rootViewController: viewController)
    let tabBarController = UITabBarController()

    tabBarController.setViewControllers([navigationController], animated: false)

    // 2. Setup viewController layout
    viewController.view.backgroundColor = .brown
    viewController.navigationItem.title = "Hello World"

    // 2. Setup navigationController layout
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.titleTextAttributes = [
      .foregroundColor: UIColor.white
    ]
    appearance.backgroundColor = .green

    navigationController.navigationBar.standardAppearance = appearance
    navigationController.navigationBar.scrollEdgeAppearance = appearance

    // 2. Setup tabBarController layout
    navigationController.tabBarItem.title = "Home"
    navigationController.tabBarItem.image = .init(systemName: "house")

    try await assert(
      of: tabBarController,
      as: .image(
        layout: .device(.iPhone16Pro)
      )
    )
  }

  func testHierarchyAndSimulatedDevice() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
        let view = UIView()
        let contentView = UIView()

        view.backgroundColor = .red
        contentView.backgroundColor = .blue

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
          contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
          contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
          contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
          contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        self.view = view
      }
    }

    try await assert(
      of: TestingViewController(),
      as: .image(
        drawHierarchyInKeyWindow: true,
        layout: .device(.iPhone16Pro)
      ),
      named: "iPhone16Pro"
    )

    try await assert(
      of: TestingViewController(),
      as: .image(layout: .device(.iPhone16Pro)),
      named: "iPhone16Pro"
    )
  }

  func testViewWithSafeAreaConcurrently() async throws {
    class TestingViewController: UIViewController {
      override func loadView() {
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
        self.view = view
      }
    }

    let viewController = TestingViewController()

    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        try await assert(
          of: viewController,
          as: .image(
            layout: .device(.iPhone16Pro),
            delay: 1
          ),
          named: "1"
        )
      }

      group.addTask {
        try await assert(
          of: viewController,
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
