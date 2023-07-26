import CiderCSSKit

final class CKUICSSAttributeExpanders {
    
    private class func validateAttributeValueCount(token: CSSToken, values: [CSSValue], min: Int, max: Int) throws {
        if values.count < min {
            throw CSSParserErrors.tooFewShorthandAttributeValues(attributeToken: token, values: values)
        }
        if values.count > max {
            throw CSSParserErrors.tooManyShorthandAttributeValues(attributeToken: token, values: values)
        }
    }
    
    class func expandAnchors(attributeToken token: CSSToken, values: [CSSValue]) throws -> [String:[CSSValue]] {
        try validateAttributeValueCount(token: token, values: values, min: 2, max: 4)
        guard let expandedAnchors = expandAnchorsUnchecked(values: values) else {
            throw CSSParserErrors.invalidAttributeValue(attributeToken: token, value: values[2])
        }
        return expandedAnchors
    }
    
    class func expandAnchorsUnchecked(values: [CSSValue]) -> [String:[CSSValue]]? {
        switch values.count {
        case 2:
            return [
                CKUICSSAttributes.anchors: [ values[0], values[0], values[1], values[1] ]
            ]
        case 4:
            return [ CKUICSSAttributes.anchors: values ]
        default:
            return nil
        }
    }
    
}
