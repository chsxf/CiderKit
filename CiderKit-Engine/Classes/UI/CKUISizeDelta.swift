import CiderCSSKit

public struct CKUISizeDelta {
    
    var horizontal: Float
    var vertical: Float
    
    public init(horizontal: Float = 0, vertical: Float = 0) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
    
    init(values: [CSSValue]) {
        guard
            values.count == 2,
            case let .length(h, _) = values[0],
            case let .length(v, _) = values[1]
        else {
            self.init()
            return
        }
        
        self.init(horizontal: h, vertical: v)
    }
    
    func toCSSValues() -> [CSSValue] {
        [ .length(horizontal, .px), .length(vertical, .px) ]
    }
    
}
