import SpriteKit
import CiderCSSKit

public final class CKUILabel : CKUIBaseNode {
    
    private let label: SKLabelNode
    
    public init(text: String, identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil) {
        label = Self.initLabel(text: text)
        super.init(type: "label", identifier: identifier, classes: classes, style: style)
        addChild(label)
    }
    
    override init(xmlElement: XMLElement) {
        let text = xmlElement.getDataPropertyValue(forName: "text")?.stringValue ?? ""
        label = Self.initLabel(text: text)
        super.init(xmlElement: xmlElement)
        addChild(label)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func initLabel(text: String) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.numberOfLines = 0
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .baseline
        label.lineBreakMode = .byWordWrapping
        label.fontSize = 12
        return label
    }
    
    public override func updateLayout() {
        super.updateLayout()
        
        guard parent != nil else { return }
        
        let localFrame = frame.offsetBy(dx: -position.x, dy: -position.y)
        
        if let color = getStyleColor(key: CSSAttributes.color) {
            label.fontColor = color
        }
        else {
            label.fontColor = SKColor.black
        }
        
        var fontFamily: String = CKUICSSValidationConfiguration.fontFamilyByKeyword["serif"]!
        if let fontFamilyValue = getStyleValue(key: CSSAttributes.fontFamily) {
            if case let CSSValue.string(fontFamilyName) = fontFamilyValue {
                fontFamily = fontFamilyName
            }
        }
        let isItalic = getStyleValue(key: CSSAttributes.fontStyle) == CSSValue.keyword("italic")
        var isBold = false
        if let fontWeightValue = getStyleValue(key: CSSAttributes.fontWeight) {
            if case let CSSValue.number(fontWeightNumber) = fontWeightValue {
                if fontWeightNumber > 700 {
                    isBold = true
                }
            }
        }
        label.fontName = FontHelpers.fontName(with: fontFamily, italic: isItalic, bold: isBold)
        
        var fontSize: Float = 12
        if let fontSizeValue = getStyleValue(key: CSSAttributes.fontSize) {
            if case let CSSValue.length(fontSizeLength, fontSizeUnit) = fontSizeValue {
                if fontSizeUnit != .pt {
                    fontSize = try! fontSizeUnit.convert(amount: fontSizeLength, to: .pt)
                }
                else {
                    fontSize = fontSizeLength
                }
            }
        }
        label.fontSize = CGFloat(fontSize)
            
        var horizontalAlign: SKLabelHorizontalAlignmentMode = .left
        if let textAlignValue = getStyleValue(key: CSSAttributes.textAlign) {
            if case let CSSValue.keyword(textAlignKeyword) = textAlignValue {
                switch textAlignKeyword {
                case "right":
                    horizontalAlign = .right
                case "center":
                    horizontalAlign = .center
                default:
                    break
                }
            }
        }
        label.horizontalAlignmentMode = horizontalAlign
        
        label.preferredMaxLayoutWidth = frame.width
        switch label.horizontalAlignmentMode {
        case .left:
            label.position.x = localFrame.minX
        case .right:
            label.position.x = localFrame.maxX
        case .center:
            label.position.x = localFrame.minX + localFrame.width / 2
        @unknown default:
            break
        }
        
        var verticalAlign: SKLabelVerticalAlignmentMode = .baseline
        if let verticalAlignValue = getStyleValue(key: CSSAttributes.verticalAlign) {
            if case let CSSValue.keyword(verticalAlignKeyword) = verticalAlignValue {
                switch verticalAlignKeyword {
                case "text-top":
                    verticalAlign = .top
                case "text-bottom":
                    verticalAlign = .bottom
                case "middle":
                    verticalAlign = .center
                default:
                    break
                }
            }
        }
        label.verticalAlignmentMode = verticalAlign
        switch label.verticalAlignmentMode {
        case .baseline, .bottom:
            label.position.y = localFrame.minY
        case .top:
            label.position.y = localFrame.maxY
        case .center:
            label.position.y = localFrame.minY + localFrame.height / 2
        @unknown default:
            break
        }
    }
    
}
