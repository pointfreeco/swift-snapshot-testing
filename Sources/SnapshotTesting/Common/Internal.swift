#if os(macOS)
import Cocoa
public typealias Image = NSImage
public typealias ImageView = NSImageView
public typealias View = NSView
#elseif os(iOS) || os(tvOS)
import UIKit
public typealias Image = UIImage
public typealias ImageView = UIImageView
public typealias View = UIView
#endif
