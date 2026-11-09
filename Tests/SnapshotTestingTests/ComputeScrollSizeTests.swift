#if os(iOS)
  import SwiftUI
  import UIKit
  import XCTest

  @testable import SnapshotTesting

  /// Tests for `computeScrollSize`. The search tests call `firstScrollView(in:)` directly, so they
  /// run on any iOS version.
  final class ComputeScrollSizeTests: BaseTestCase {
    // MARK: - Search rules

    func testFirstScrollViewReturnsRootScrollView() {
      let root = makeScrollView(width: 375, contentHeight: 2000)
      root.addSubview(makeScrollView(width: 375, contentHeight: 2000))

      XCTAssertIdentical(firstScrollView(in: root), root)
    }

    func testFirstScrollViewSkipsTextView() {
      let root = makeRoot()
      let textView = UITextView(frame: .init(x: 0, y: 0, width: 375, height: 100))
      textView.text = String(repeating: "Text\n", count: 100)
      let scrollView = makeScrollView(width: 375, contentHeight: 2000)
      root.addSubview(textView)
      root.addSubview(scrollView)

      XCTAssertIdentical(firstScrollView(in: root), scrollView)
    }

    func testFirstScrollViewSkipsHiddenScrollView() {
      let root = makeRoot()
      let hidden = makeScrollView(width: 375, contentHeight: 2000)
      hidden.isHidden = true
      let scrollView = makeScrollView(width: 375, contentHeight: 2000)
      root.addSubview(hidden)
      root.addSubview(scrollView)

      XCTAssertIdentical(firstScrollView(in: root), scrollView)
    }

    func testFirstScrollViewSkipsNarrowScrollView() {
      let root = makeRoot()
      let sidebar = makeScrollView(width: 125, contentHeight: 2000)
      let detail = makeScrollView(width: 250, contentHeight: 2000)
      detail.frame.origin.x = 125
      root.addSubview(sidebar)
      root.addSubview(detail)

      XCTAssertIdentical(firstScrollView(in: root), detail)
    }

    func testFirstScrollViewSkipsCarouselAndItsContent() {
      let root = makeRoot()
      let carousel = makeScrollView(width: 375, contentHeight: 200)
      carousel.frame.size.height = 200
      carousel.contentSize.width = 2000
      let scrollViewInCarousel = makeScrollView(width: 375, contentHeight: 2000)
      carousel.addSubview(scrollViewInCarousel)
      let scrollView = makeScrollView(width: 375, contentHeight: 2000)
      root.addSubview(carousel)
      root.addSubview(scrollView)

      XCTAssertIdentical(firstScrollView(in: root), scrollView)
    }

    func testFirstScrollViewPrefersShallowerScrollView() {
      let root = makeRoot()
      let container = UIView(frame: root.bounds)
      let deep = makeScrollView(width: 375, contentHeight: 2000)
      container.addSubview(deep)
      let shallow = makeScrollView(width: 375, contentHeight: 2000)
      root.addSubview(container)
      root.addSubview(shallow)

      XCTAssertIdentical(firstScrollView(in: root), shallow)
    }

    func testFirstScrollViewReturnsNilWithoutCandidate() {
      let root = makeRoot()
      root.addSubview(UITextView(frame: root.bounds))
      root.addSubview(makeScrollView(width: 100, contentHeight: 2000))

      XCTAssertNil(firstScrollView(in: root))
    }

    func testFirstScrollViewFindsScrollViewOfTestContentScrollSize() {
      // NB: The search finds the same scroll view as `contentScrollView(for:)`.
      let viewController = UIViewController()
      viewController.view.frame = .init(x: 0, y: 0, width: 375, height: 812)
      let scrollView = makeScrollView(width: 375, contentHeight: 2000)
      viewController.view.addSubview(scrollView)
      if #available(iOS 15.0, *) {
        viewController.setContentScrollView(scrollView)
        XCTAssertIdentical(viewController.contentScrollView(for: .top), scrollView)
      }

      XCTAssertIdentical(firstScrollView(in: viewController.view), scrollView)
    }

    // MARK: - Snapshot size

    func testComputeScrollSizeWithTableViewController() {
      let viewController = TableViewController()

      let image = snapshotImage(of: viewController, computeScrollSize: true)

      let tableView = viewController.tableView!
      if #available(iOS 15.0, *) {
        // NB: UIKit sets no content scroll view here, so the snapshot uses the search.
        XCTAssertNil(viewController.contentScrollView(for: .top))
      }
      XCTAssertEqual(image.size.width, 375)
      XCTAssertEqual(
        image.size.height, tableView.contentSize.height + safeAreaHeight, accuracy: 0.5)
      XCTAssertGreaterThan(image.size.height, 812)
    }

    func testComputeScrollSizeWithoutSetContentScrollView() {
      let viewController = UIViewController()
      let scrollView = UIScrollView()
      scrollView.translatesAutoresizingMaskIntoConstraints = false
      viewController.view.addSubview(scrollView)
      let content = UIView()
      content.translatesAutoresizingMaskIntoConstraints = false
      scrollView.addSubview(content)
      NSLayoutConstraint.activate([
        scrollView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
        scrollView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
        scrollView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
        scrollView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
        content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
        content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
        content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
        content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        content.heightAnchor.constraint(equalToConstant: 2000),
      ])

      let image = snapshotImage(of: viewController, computeScrollSize: true)

      if #available(iOS 15.0, *) {
        XCTAssertNil(viewController.contentScrollView(for: .top))
      }
      XCTAssertEqual(image.size.width, 375)
      XCTAssertEqual(image.size.height, 2000 + safeAreaHeight, accuracy: 0.5)
    }

    func testComputeScrollSizeOffKeepsDeviceSize() {
      let image = snapshotImage(of: TableViewController(), computeScrollSize: false)

      XCTAssertEqual(image.size, CGSize(width: 375, height: 812))
    }

    func testComputeScrollSizeWithUIView() {
      let dataSource = DataSource()
      let tableView = UITableView(frame: .init(x: 0, y: 0, width: 375, height: 812))
      tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      tableView.dataSource = dataSource

      let image = snapshotImage(of: tableView as UIView, as: .image(computeScrollSize: true))

      // NB: No safe area, so the image is as tall as the content.
      XCTAssertEqual(image.size.width, 375)
      XCTAssertEqual(image.size.height, tableView.contentSize.height, accuracy: 0.5)
      XCTAssertGreaterThan(image.size.height, 812)
    }

    func testComputeScrollSizeWithSwiftUIScrollView() {
      let view = ScrollView {
        VStack {
          ForEach(0..<100) { Text("Row \($0)") }
        }
      }

      let image = snapshotImage(
        of: view, as: .image(layout: .device(config: .iPhoneX), computeScrollSize: true))
      let imageOff = snapshotImage(
        of: view, as: .image(layout: .device(config: .iPhoneX), computeScrollSize: false))

      // NB: The content is narrow, but the image keeps the device width.
      XCTAssertEqual(image.size.width, 375)
      XCTAssertGreaterThan(image.size.height, 812)
      XCTAssertEqual(imageOff.size, CGSize(width: 375, height: 812))
    }

    func testComputeScrollSizeKeepsDeviceSizeForShortContent() {
      let viewController = UIViewController()
      viewController.view.frame = .init(x: 0, y: 0, width: 375, height: 812)
      let scrollView = makeScrollView(width: 375, contentHeight: 200)
      scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      viewController.view.addSubview(scrollView)

      let image = snapshotImage(of: viewController, computeScrollSize: true)

      XCTAssertEqual(image.size, CGSize(width: 375, height: 812))
    }

    func testComputeScrollSizeKeepsViewsOutsideScrollView() {
      let viewController = UIViewController()
      viewController.view.frame = .init(x: 0, y: 0, width: 375, height: 812)
      let header = UIView(frame: .init(x: 0, y: 0, width: 375, height: 100))
      header.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
      let scrollView = UIScrollView(frame: .init(x: 0, y: 100, width: 375, height: 712))
      scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      scrollView.contentInsetAdjustmentBehavior = .never
      scrollView.contentSize = .init(width: 375, height: 2000)
      viewController.view.addSubview(header)
      viewController.view.addSubview(scrollView)

      let image = snapshotImage(of: viewController, computeScrollSize: true)

      // NB: 100-point header + 2000 points of content.
      XCTAssertEqual(image.size, CGSize(width: 375, height: 2100))
    }

    // MARK: - Helpers

    private final class DataSource: NSObject, UITableViewDataSource {
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        50
      }

      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
      {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        return cell
      }
    }

    /// The top and bottom safe area of `.iPhoneX`. Read from the config, because
    /// `adjustedContentInset` is zero after the snapshot.
    private let safeAreaHeight =
      ViewImageConfig.iPhoneX.safeArea.top + ViewImageConfig.iPhoneX.safeArea.bottom

    private final class TableViewController: UITableViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      }

      override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        50
      }

      override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
      {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        return cell
      }
    }

    private func makeRoot() -> UIView {
      UIView(frame: .init(x: 0, y: 0, width: 375, height: 812))
    }

    private func makeScrollView(width: CGFloat, contentHeight: CGFloat) -> UIScrollView {
      let scrollView = UIScrollView(frame: .init(x: 0, y: 0, width: width, height: 812))
      scrollView.contentSize = .init(width: width, height: contentHeight)
      return scrollView
    }

    private func snapshotImage(
      of viewController: UIViewController, computeScrollSize: Bool
    ) -> UIImage {
      snapshotImage(
        of: viewController, as: .image(on: .iPhoneX, computeScrollSize: computeScrollSize))
    }

    private func snapshotImage<Value>(
      of value: Value, as strategy: Snapshotting<Value, UIImage>
    ) -> UIImage {
      var result: UIImage?
      let done = expectation(description: "snapshot")
      strategy.snapshot(value).run { image in
        result = image
        done.fulfill()
      }
      wait(for: [done], timeout: 30)
      return result ?? UIImage()
    }
  }
#endif
