@testable import XCSnapshotTesting

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(macOS) || os(iOS) || os(tvOS) || os(visionOS)
extension CGPath {
    /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
    static var heart: CGPath {
        let scale: CGFloat = 30.0
        let path = CGMutablePath()

        path.move(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
        path.addLine(to: CGPoint(x: 0.0 * scale, y: 2.0 * scale))
        path.addQuadCurve(
            to: CGPoint(x: 1.0 * scale, y: 3.0 * scale),
            control: CGPoint(x: 0.125 * scale, y: 2.875 * scale)
        )
        path.addQuadCurve(
            to: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
            control: CGPoint(x: 1.875 * scale, y: 2.875 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 3.0 * scale, y: 1.0 * scale),
            control1: CGPoint(x: 2.5 * scale, y: 2.0 * scale),
            control2: CGPoint(x: 3.0 * scale, y: 1.5 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 2.0 * scale, y: 0.0 * scale),
            control1: CGPoint(x: 3.0 * scale, y: 0.5 * scale),
            control2: CGPoint(x: 2.5 * scale, y: 0.0 * scale)
        )
        path.addLine(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
        path.closeSubpath()

        path.addEllipse(
            in: CGRect(
                origin: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
                size: CGSize(width: scale, height: scale)
            )
        )

        return path
    }
}
#endif

#if os(iOS) || os(tvOS) || os(visionOS)
extension UIBezierPath {
    /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
    static var heart: UIBezierPath {
        UIBezierPath(cgPath: .heart)
    }
}
#endif

#if os(macOS)
extension NSTextField {
    var text: String {
        get { self.stringValue }
        set { self.stringValue = newValue }
    }
}

extension NSBezierPath {
    /// Creates an approximation of a heart at a 45º angle with a circle above, using all available element types:
    static var heart: NSBezierPath {
        let scale: CGFloat = 30.0
        let path = NSBezierPath()

        path.move(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
        path.line(to: CGPoint(x: 0.0 * scale, y: 2.0 * scale))
        path.curve(
            to: CGPoint(x: 1.0 * scale, y: 3.0 * scale),
            controlPoint1: CGPoint(x: 0.0 * scale, y: 2.5 * scale),
            controlPoint2: CGPoint(x: 0.5 * scale, y: 3.0 * scale)
        )
        path.curve(
            to: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
            controlPoint1: CGPoint(x: 1.5 * scale, y: 3.0 * scale),
            controlPoint2: CGPoint(x: 2.0 * scale, y: 2.5 * scale)
        )
        path.curve(
            to: CGPoint(x: 3.0 * scale, y: 1.0 * scale),
            controlPoint1: CGPoint(x: 2.5 * scale, y: 2.0 * scale),
            controlPoint2: CGPoint(x: 3.0 * scale, y: 1.5 * scale)
        )
        path.curve(
            to: CGPoint(x: 2.0 * scale, y: 0.0 * scale),
            controlPoint1: CGPoint(x: 3.0 * scale, y: 0.5 * scale),
            controlPoint2: CGPoint(x: 2.5 * scale, y: 0.0 * scale)
        )
        path.line(to: CGPoint(x: 0.0 * scale, y: 0.0 * scale))
        path.close()

        path.appendOval(
            in: CGRect(
                origin: CGPoint(x: 2.0 * scale, y: 2.0 * scale),
                size: CGSize(width: scale, height: scale)
            )
        )

        return path
    }
}
#endif
