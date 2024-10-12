import CiderCSSKit

public struct CKUISizeDelta {
    
    var horizontal: Float
    var vertical: Float
    
    public init(horizontal: Float = 0, vertical: Float = 0) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
    
    init(values: [CSSValue]) {
        guard values.count == 2 else {
            self.init()
            return
        }

        var h: Float
        switch values[0] {
            case let .length(lengthH, _):
                h = lengthH
            default:
                h = 0
        }

        var v: Float
        switch values[1] {
            case let .length(lengthV, _):
                v = lengthV
            default:
                v = 0
        }

        self.init(horizontal: h, vertical: v)
    }
    
    func toCSSValues() -> [CSSValue] {
        [ .length(horizontal, .px), .length(vertical, .px) ]
    }
    
}
