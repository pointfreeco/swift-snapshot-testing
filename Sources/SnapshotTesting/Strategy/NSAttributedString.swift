import UIKit

extension Strategy where Snapshottable == NSAttributedString, Format == UIImage {
  public static var image: Strategy {
    return Strategy<UIView, UIImage>.image.pullback { string in
      let label = UILabel.init(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
      label.attributedText = string
      return label
    }
  }
}

extension Strategy where Snapshottable == NSAttributedString, Format == String {
  public static var html: Strategy {
    var strategy: Strategy = Strategy<String, String>.lines.pullback { string in
      let htmlData = try! string.data(
        from: NSRange(location: 0, length: string.length),
        documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
      )
      return String(data: htmlData, encoding: .utf8)!
    }
    strategy.pathExtension = "html"
    return strategy
  }
}
