import CiderCSSKit

final class CKUICSSShorthandAttributeExpanders {
    
    private class func validateAttributeValues(token: CSSToken, values: [CSSValue], min: Int, max: Int) throws {
        if values.count < min {
            throw CSSParserErrors.tooFewShorthandAttributeValues(attributeToken: token, values: values)
        }
        if values.count > max {
            throw CSSParserErrors.tooManyShorthandAttributeValues(attributeToken: token, values: values)
        }
        
        for value in values {
            guard case .number = value else {
                throw CSSParserErrors.invalidShorthandAttributeValue(attributeToken: token, value: value)
            }
        }
    }
    
    class func expandAnchors(attributeToken token: CSSToken, values: [CSSValue]) throws -> [String:[CSSValue]] {
        try validateAttributeValues(token: token, values: values, min: 2, max: 4)
        guard let expandedAnchors = expandAnchorsUnchecked(values: values) else {
            throw CSSParserErrors.invalidAttributeValue(attributonToken: token, value: values[2])
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
