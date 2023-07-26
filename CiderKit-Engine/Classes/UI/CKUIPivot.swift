import CiderCSSKit

public struct CKUIPivot {
    
    var x: Float
    var y: Float
    
    public init(x: Float = 0, y: Float = 0) {
        self.x = x
        self.y = y
    }
    
    init(values: [CSSValue]) {
        guard
            values.count >= 2,
            case let .percentage(x) = values[0],
            case let .percentage(y) = values[1]
        else {
            self.init()
            return
        }
        
        self.init(x: x / 100, y: y / 100)
    }
    
    func toCSSValues() -> [CSSValue] {
        [ .percentage(x * 100), .percentage(y * 100), .length(0, .px) ]
    }
    
}
