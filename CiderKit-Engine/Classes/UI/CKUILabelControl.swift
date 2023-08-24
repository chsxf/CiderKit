import SpriteKit
import CiderCSSKit

protocol CKUILabelControl {
    
    var label: SKLabelNode? { get}
    
}

extension CKUILabelControl where Self: CKUIBaseNode {
    
    func updateFontColor() {
        guard let label = self.label else { return }
        
        if let color = self.getStyleColor(key: CSSAttributes.color) {
            label.fontColor = color
        }
        else {
            label.fontColor = SKColor.black
        }
    }
    
    func updateFontName() {
        guard let label = self.label else { return }
        
        var fontFamily: String = CKUICSSValidationConfiguration.fontFamilyByKeyword["serif"]!
        if let fontFamilyValue = self.getStyleValue(key: CSSAttributes.fontFamily) {
            if case let CSSValue.string(fontFamilyName) = fontFamilyValue {
                fontFamily = fontFamilyName
            }
        }
        let isItalic = getStyleValue(key: CSSAttributes.fontStyle) == CSSValue.keyword("italic")
        var isBold = false
        if let fontWeightValue = self.getStyleValue(key: CSSAttributes.fontWeight) {
            if case let CSSValue.number(fontWeightNumber) = fontWeightValue {
                if fontWeightNumber > 700 {
                    isBold = true
                }
            }
        }
        label.fontName = FontHelpers.fontName(with: fontFamily, italic: isItalic, bold: isBold)
    }
    
    func updateFontSize() {
        guard let label = self.label else { return }
        
        let fontSize: Float = self.getStyleLength(key: CSSAttributes.fontSize, unit: .pt) ?? 12
        label.fontSize = CGFloat(fontSize)
    }
    
}
