import CiderCSSKit

public class CKUICSSValidationConfiguration: CSSValidationConfiguration {
    
    public static let `default`: CKUICSSValidationConfiguration = CKUICSSValidationConfiguration()
    
    private static let customValueTypesByAttribute: [String : [CSSValueType]] = [
        CKUICSSAttributes.anchoredPosition: [.number],
        CKUICSSAttributes.anchors: [.number],
        CKUICSSAttributes.backgroundColor: [.color],
        CKUICSSAttributes.backgroundImage: [.custom("CKUISpriteDescriptor")],
        CKUICSSAttributes.color: [.color],
        CKUICSSAttributes.fontFamily: [.string],
        CKUICSSAttributes.fontSize: [.number],
        CKUICSSAttributes.fontStyle: [.string],
        CKUICSSAttributes.fontWeight: [.number],
        CKUICSSAttributes.sizeDelta: [.number],
        CKUICSSAttributes.transformOrigin: [.number],
    ]
    
    private static let horizontalPositionalKeywords: [String: CSSValue] = [
        "center": .number(0.5, .none),
        "left": .number(0, .none),
        "right": .number(1, .none),
    ]
    
    private static let verticalPositionalKeywords: [String: CSSValue] = [
        "bottom": .number(0, .none),
        "middle": .number(0.5, .none),
        "top": .number(1, .none)
    ]
    
    #if os(watchOS)
    private static let sansSerifFontName = "SF Compact"
    #else
    private static let sansSerifFontName = "SF Pro"
    #endif
    
    private static let fontFamilyKeywords: [String: CSSValue] = [
        "sans-serif": .string(sansSerifFontName),
        "serif": .string("New York"),
        "monospace": .string("SF Mono")
    ]
    
    private static let fontStyleKeywords: [String: CSSValue] = [
        "normal": .string("normal"),
        "italic": .string("italic")
    ]
        
    private static let fontWeightKeywords: [String: CSSValue] = [
        "normal": .number(400, .none),
        "bold": .number(700, .none)
    ]
    
    private static let expansionMethodByShorthandAttribute: [String: CSSShorthandAttributeExpansion] = [
        CKUICSSAttributes.anchors: CKUICSSShorthandAttributeExpanders.expandAnchors(attributeToken:values:),
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
    
    override open func parseKeyword(attributeToken: CSSToken, potentialKeyword: CSSToken) throws -> CSSValue {
        guard attributeToken.type == .string, let attributeName = attributeToken.value as? String else {
            throw CSSParserErrors.invalidToken(attributeToken)
        }
        
        guard potentialKeyword.type == .string, let stringTokenValue = potentialKeyword.value as? String else {
            throw CSSParserErrors.invalidToken(potentialKeyword)
        }
        
        switch attributeName {
        case CKUICSSAttributes.anchoredPosition, CKUICSSAttributes.anchors, CKUICSSAttributes.transformOrigin:
            if let keyword = Self.horizontalPositionalKeywords[stringTokenValue] ?? Self.verticalPositionalKeywords[stringTokenValue] {
                return keyword
            }
        case CKUICSSAttributes.fontFamily:
            if let keyword = Self.fontFamilyKeywords[stringTokenValue] {
                return keyword
            }
        case CKUICSSAttributes.fontStyle:
            if let keyword = Self.fontStyleKeywords[stringTokenValue] {
                return keyword
            }
        case CKUICSSAttributes.fontWeight:
            if let keyword = Self.fontWeightKeywords[stringTokenValue] {
                return keyword
            }
        default:
            if let scalingMethod = CKUIScalingMethod(rawValue: stringTokenValue) {
                return .custom(scalingMethod)
            }
        }
        
        throw CSSParserErrors.invalidKeyword(attributeToken: attributeToken, potentialKeyword: potentialKeyword)
    }
    
    private static func parseSpriteFunction(functionToken: CSSToken, attributes: [CSSValue]) throws -> CSSValue {
        if attributes.count < 2 {
            throw CSSParserErrors.tooFewFunctionAttributes(functionToken: functionToken, values: attributes)
        }

        guard case let .string(spriteName) = attributes[0] else {
            throw CSSParserErrors.invalidFunctionAttribute(functionToken: functionToken, value: attributes[0])
        }
        
        guard
            case let .custom(equatable) = attributes[1],
            let scalingMethod = equatable as? CKUIScalingMethod
        else {
            throw CSSParserErrors.invalidFunctionAttribute(functionToken: functionToken, value: attributes[1])
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
            throw CSSParserErrors.tooFewFunctionAttributes(functionToken: functionToken, values: attributes)
        }
        else if attributes.count > 1 {
            throw CSSParserErrors.tooManyFunctionAttributes(functionToken: functionToken, values: attributes)
        }

        guard case let .string(reference) = attributes[0] else {
            throw CSSParserErrors.invalidFunctionAttribute(functionToken: functionToken, value: attributes[0])
        }

        return .custom(CKUISpriteDescriptor.spriteref(reference))
    }
    
}
