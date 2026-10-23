import XCTest
@testable import SnapshotTesting

class DelayTests: XCTestCase {
  func testDelayViewDidLoad() {
    let  sut = DelayedViewController()
    
    assertSnapshot(matching: sut, as: .image(on: .iPhone13, delay: 2))
  }
  func testViewDidLoad() {
    let  sut = DelayedViewController()
    
    assertSnapshot(matching: sut, as: .image(on: .iPhone13))
  }
  func testWaitViewDidLoad() {
      let  sut = DelayedViewController()
      
    assertSnapshot(matching: sut, as: .wait(for: 2, on: .image(on: .iPhone13)))
  }
}

private final class DelayedViewController: UIViewController {
  
  private lazy var topLabel = UILabel()
  private lazy var bottomLabel = UILabel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.topLabel.text = "Goodbye viewDidLoad"
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.bottomLabel.text = "Goodbye viewDidAppear"
    }
  }
  
  private func setupUI() {
    view.backgroundColor = .white
    
    topLabel.text = "Hello viewDidLoad"
    bottomLabel.text = "Hello viewDidAppear"
    topLabel.translatesAutoresizingMaskIntoConstraints = false
    bottomLabel.translatesAutoresizingMaskIntoConstraints = false
    
    view.addSubview(topLabel)
    view.addSubview(bottomLabel)
    
    NSLayoutConstraint.activate([
      topLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      topLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      bottomLabel.topAnchor.constraint(equalTo: topLabel.bottomAnchor),
      bottomLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
    ])
  }
}
