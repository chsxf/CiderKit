import CiderCSSKit

public struct CKUIPadding {
    
    public var top: Float
    public var right: Float
    public var bottom: Float
    public var left: Float
    
    public init(top: Float = 0, right: Float = 0, bottom: Float = 0, left: Float = 0) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }
    
    init(values: [CSSValue]) {
        guard values.count == 4 else {
            self.init()
            return
        }
        
        self.init(
            top: Self.getPixelLengthOrZero(values[0]),
            right: Self.getPixelLengthOrZero(values[1]),
            bottom: Self.getPixelLengthOrZero(values[2]),
            left: Self.getPixelLengthOrZero(values[3])
        )
    }
    
    func toCSSValues() -> [CSSValue] {
        [
            .length(top, .px),
            .length(right, .px),
            .length(bottom, .px),
            .length(left, .px)
        ]
    }
    
    private static func getPixelLengthOrZero(_ cssValue: CSSValue) -> Float {
        switch cssValue {
        case let .length(value, unit):
            return try! unit.convert(amount: value, to: .px)
        default:
            return 0
        }
    }
    
}
