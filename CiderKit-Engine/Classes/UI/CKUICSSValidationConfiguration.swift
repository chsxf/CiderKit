import CiderCSSKit

public class CKUICSSValidationConfiguration: CSSValidationConfiguration {
    
    public static let `default`: CKUICSSValidationConfiguration = CKUICSSValidationConfiguration()
    
    private static let customValueTypesByAttribute: [String : [CSSValueType]] = [
        CKUICSSAttributes.anchoredPosition: [.number],
        CKUICSSAttributes.anchoredPositionX: [.number],
        CKUICSSAttributes.anchoredPositionY: [.number],
        CKUICSSAttributes.sizeDelta: [.number],
        CKUICSSAttributes.sizeDeltaWidth: [.number],
        CKUICSSAttributes.sizeDeltaHeight: [.number],
        CKUICSSAttributes.anchors: [.number],
        CKUICSSAttributes.anchorsXMin: [.number],
        CKUICSSAttributes.anchorsXMax: [.number],
        CKUICSSAttributes.anchorsYMin: [.number],
        CKUICSSAttributes.anchorsYMax: [.number],
        CKUICSSAttributes.pivot: [.number],
        CKUICSSAttributes.pivotX: [.number],
        CKUICSSAttributes.pivotY: [.number],
        "color": [.color]
    ]
    
    private static let positionKeywords: [String: CSSValue] = [
        "bottom": .number(0, .none),
        "center": .number(0.5, .none),
        "left": .number(0, .none),
        "right": .number(1, .none),
        "middle": .number(0.5, .none),
        "top": .number(1, .none)
    ]
    
    private static let expansionMethodByShorthandAttribute: [String: CSSShorthandAttributeExpansion] = [
        CKUICSSAttributes.anchoredPosition: CKUICSSShorthandAttributeExpanders.expandAnchoredPosition(attributeToken:values:),
        CKUICSSAttributes.sizeDelta: CKUICSSShorthandAttributeExpanders.expandSizeDelta(attributeToken:values:),
        CKUICSSAttributes.anchors: CKUICSSShorthandAttributeExpanders.expandAnchors(attributeToken:values:),
        CKUICSSAttributes.pivot: CKUICSSShorthandAttributeExpanders.expandPivot(attributeToken:values:)
    ]
    
    public override var valueTypesByAttribute: [String : [CSSValueType]] { Self.customValueTypesByAttribute }
    public override var shorthandAttributes: [String : CSSShorthandAttributeExpansion] { Self.expansionMethodByShorthandAttribute }
    
    override open func parseFunction(functionToken: CSSToken, attributes: [CSSValue]) throws -> CSSValue {
        guard let functionName = functionToken.value as? String else { throw CSSParserErrors.invalidToken(functionToken) }
        
        switch functionName {
        case "sprite":
            return try Self.parseSpriteFunction(functionToken: functionToken, attributes: attributes)
        case "spriteref":
            return try Self.parseSpriteReferenceFunction(functionToken: functionToken, attributes: attributes)
        default:
            throw CSSParserErrors.unknownFunction(functionToken)
        }
    }
    
    override open func parseKeyword(stringToken: CSSToken) throws -> CSSValue {
        guard stringToken.type == .string else { throw CSSParserErrors.invalidToken(stringToken) }
        
        let stringTokenValue = stringToken.value as! String
        
        if let positionKeyword = Self.positionKeywords[stringTokenValue] {
            return positionKeyword
        }
        
        if let scalingMethod = CKUIScalingMethod(rawValue: stringTokenValue) {
            return .custom(scalingMethod)
        }
        
        throw CSSParserErrors.invalidKeyword(stringToken)
    }
    
    private static func parseSpriteFunction(functionToken: CSSToken, attributes: [CSSValue]) throws -> CSSValue {
        if attributes.count < 2 {
            throw CSSParserErrors.tooFewFunctionAttributes(functionToken, attributes)
        }

        guard case let .string(spriteName) = attributes[0] else {
            throw CSSParserErrors.invalidFunctionAttribute(functionToken, attributes[0])
        }
        
        guard
            case let .custom(equatable) = attributes[1],
            let scalingMethod = equatable as? CKUIScalingMethod
        else {
            throw CSSParserErrors.invalidFunctionAttribute(functionToken, attributes[1])
        }

        switch scalingMethod {
        case .scaled:
            return .custom(CKUISpriteDescriptor.sprite(spriteName, scalingMethod, 0, 0, 0, 0))

        case .sliced:
            let components = try CSSValue.parseFloatComponents(numberOfComponents: 4, functionToken: functionToken, attributes: attributes, from: 2)
            return .custom(CKUISpriteDescriptor.sprite(spriteName, scalingMethod, components[0], components[1], components[2], components[3]))
        }
    }

    private static func parseSpriteReferenceFunction(functionToken: CSSToken, attributes: [CSSValue]) throws -> CSSValue {
        if attributes.count < 1 {
            throw CSSParserErrors.tooFewFunctionAttributes(functionToken, attributes)
        }
        else if attributes.count > 1 {
            throw CSSParserErrors.tooManyFunctionAttributes(functionToken, attributes)
        }

        guard case let .string(reference) = attributes[0] else {
            throw CSSParserErrors.invalidFunctionAttribute(functionToken, attributes[0])
        }

        return .custom(CKUISpriteDescriptor.spriteref(reference))
    }
    
}
