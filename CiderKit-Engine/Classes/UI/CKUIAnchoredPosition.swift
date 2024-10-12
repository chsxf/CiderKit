import CiderCSSKit

public struct CKUIAnchoredPosition {
    
    var x: Float
    var y: Float
    
    public init(x: Float = 0, y: Float = 0) {
        self.x = x
        self.y = y
    }
    
    init(values: [CSSValue]) {
        guard values.count == 2 else {
            self.init()
            return
        }

        var x: Float
        switch values[0] {
            case let .length(lengthX, _):
                x = lengthX
            default:
                x = 0
        }

        var y: Float
        switch values[1] {
            case let .length(lengthY, _):
                y = lengthY
            default:
                y = 0
        }

        self.init(x: x, y: y)
    }
    
    func toCSSValues() -> [CSSValue] {
        [ .length(x, .px), .length(y, .px) ]
    }
    
}
