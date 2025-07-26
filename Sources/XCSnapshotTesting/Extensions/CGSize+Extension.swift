#if os(iOS) || os(tvOS) || os(watchOS) || os(macOS) || os(visionOS)
import CoreGraphics

extension CGSize {

    func scaleThatFits(_ size: CGSize) -> CGFloat {
        if size.width <= width && size.height <= height {
            return 1
        }

        let scaleWidth = width / size.width
        let scaleHeight = height / size.height

        return min(scaleWidth, scaleHeight)
    }

    func scaleToFit(_ size: CGSize) -> CGSize {
        let scale = scaleThatFits(size)

        return CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
    }
}

extension CGRect {

    func scale(by scale: CGFloat) -> CGRect {
        guard scale != 1 else {
            return self
        }

        let center = CGPoint(x: midX, y: midY)

        let scaledSize = CGSize(
            width: width * scale,
            height: height * scale
        )

        return .init(
            x: center.x - scaledSize.width / 2,
            y: center.y - scaledSize.height / 2,
            width: scaledSize.width,
            height: scaledSize.height
        )
    }
}

extension CGSize {

    /// 440 x 956
    static let screen6_9 = CGSize(width: 440, height: 956)

    /// 430 x 932
    static let screen6_7v2 = CGSize(width: 430, height: 932)

    /// 428 x 926
    static let screen6_7v1 = CGSize(width: 428, height: 926)

    /// 414 x 896
    static let screen6_5 = CGSize(width: 414, height: 896)

    /// 402 x 874
    static let screen6_3 = CGSize(width: 402, height: 874)

    /// 414 x 896
    static let screen6_1v3 = CGSize(width: 414, height: 896)

    /// 393 x 852
    static let screen6_1v2 = CGSize(width: 393, height: 852)

    /// 390 x 844
    static let screen6_1v1 = CGSize(width: 390, height: 844)

    /// 375 x 812
    static let screen5_8 = CGSize(width: 375, height: 812)

    /// 414 x 736
    static let screen5_5 = CGSize(width: 414, height: 736)

    /// 375 x 812
    static let screen5_4 = CGSize(width: 375, height: 812)

    /// 375 x 667
    static let screen4_7 = CGSize(width: 375, height: 667)

    func reflected() -> CGSize {
        .init(width: height, height: width)
    }
}
#endif
