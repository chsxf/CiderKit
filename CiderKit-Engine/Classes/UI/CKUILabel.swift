import SpriteKit
import CiderCSSKit

public final class CKUILabel : CKUIBaseNode, CKUILabelControl {

    private static let textCustomData: String = "text"

    internal var label: SKLabelNode?
    
    public convenience init(text: String, identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil) {
        self.init(identifier: identifier, classes: classes, style: style, customData: ["text": text])
    }
    
    public required init(type: String = "lebel", identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil, customData: [String: any Sendable]? = nil) {
        super.init(type: type, identifier: identifier, classes: classes, style: style, customData: customData)
        
        label = Self.initLabel(text: customData![Self.textCustomData] as! String)
        addChild(label!)
    }

    public override class func parseCustomData(_ customData: [String : String]) throws -> [String : any Sendable] {
        guard let text = customData[Self.textCustomData] else {
            throw CKUILoaderErrors.missingCustomData(name: Self.textCustomData)
        }

        var parsedCustomData = try super.parseCustomData(customData)
        parsedCustomData[Self.textCustomData] = text
        return parsedCustomData
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
        
        updateFontColor()
        updateFontName()
        updateFontSize()
        
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
        label!.horizontalAlignmentMode = horizontalAlign
        
        label!.preferredMaxLayoutWidth = frame.width
        switch label!.horizontalAlignmentMode {
        case .left:
            label!.position.x = localFrame.minX
        case .right:
            label!.position.x = localFrame.maxX
        case .center:
            label!.position.x = localFrame.minX + localFrame.width / 2
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
        label!.verticalAlignmentMode = verticalAlign
        switch label!.verticalAlignmentMode {
        case .baseline, .bottom:
            label!.position.y = localFrame.minY
        case .top:
            label!.position.y = localFrame.maxY
        case .center:
            label!.position.y = localFrame.minY + localFrame.height / 2
        @unknown default:
            break
        }
    }
    
}
