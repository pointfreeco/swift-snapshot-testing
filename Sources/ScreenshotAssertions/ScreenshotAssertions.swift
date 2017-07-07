import XCTest

public func assertScreenshot(
  matching view: UIView,
  _ file: StaticString = #file,
  _ function: String = #function,
  _ line: UInt = #line
  ) {
  let fileURL = URL(fileURLWithPath: String(describing: file))
  let screenshotsURL = fileURL.deletingLastPathComponent().appendingPathComponent("__Screenshots__")
  let fileManager = FileManager.default
  
  try! fileManager.createDirectory(
    at: screenshotsURL,
    withIntermediateDirectories: true,
    attributes: nil
  )
  
  UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
  let context = UIGraphicsGetCurrentContext()!
  view.layer.render(in: context)
  let image = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  let data = UIImagePNGRepresentation(image)!
  
  let screenshotURL = screenshotsURL
    .appendingPathComponent("\(fileURL.deletingPathExtension().lastPathComponent).\(function).png")
  
  guard fileManager.fileExists(atPath: screenshotURL.path) else {
    try! data.write(to: screenshotURL)
    return
  }
  
  let existingData = try! Data(contentsOf: screenshotURL)
  
  XCTAssert(
    existingData == data,
    "\(screenshotURL.debugDescription) does not match screenshot",
    file: file,
    line: line
  )
}
