import SpriteKit
import CiderCSSKit

protocol CKUILabelControl {
    
    var label: SKLabelNode! { get}
    
}

extension CKUILabelControl where Self: CKUIBaseNode {
    
    func updateFontColor() {
        if let color = self.getStyleColor(key: CSSAttributes.color) {
            self.label.fontColor = color
        }
        else {
            self.label.fontColor = SKColor.black
        }
    }
    
    func updateFontName() {
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
        self.label.fontName = FontHelpers.fontName(with: fontFamily, italic: isItalic, bold: isBold)
    }
    
    func updateFontSize() {
        let fontSize: Float = self.getStyleLength(key: CSSAttributes.fontSize, unit: .pt) ?? 12
        self.label.fontSize = CGFloat(fontSize)
    }
    
}
