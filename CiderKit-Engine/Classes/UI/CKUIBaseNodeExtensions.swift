import SpriteKit
import CiderCSSKit

extension CKUIBaseNode {
    
    public func getStyleColor(key: String) -> SKColor {
        guard
            let values = getStyleValues(key: key),
            case let CSSValue.color(r, g, b, a) = values[0]
        else {
            return SKColor.white
        }
        
        return SKColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }
    
}
