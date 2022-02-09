import Foundation

extension UInt8 {
    func diff(between other: UInt8) -> UInt8 {
        if other > self {
            return other - self
        } else {
            return self - other
        }
    }
}
