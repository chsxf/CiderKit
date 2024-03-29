import CiderCSSKit

public struct CKUIAnchoredPosition {
    
    var x: Float
    var y: Float
    
    public init(x: Float = 0, y: Float = 0) {
        self.x = x
        self.y = y
    }
    
    init(values: [CSSValue]) {
        guard
            values.count == 2,
            case let .length(x, _) = values[0],
            case let .length(y, _) = values[1]
        else {
            self.init()
            return
        }
        
        self.init(x: x, y: y)
    }
    
    func toCSSValues() -> [CSSValue] {
        [ .length(x, .px), .length(y, .px) ]
    }
    
}
