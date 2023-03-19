import CiderCSSKit

final class CKUICSSShorthandAttributeExpanders {
    
    private class func validateAttributeValues(token: CSSToken, values: [CSSValue], min: Int, max: Int) throws {
        if values.count < min {
            throw CSSParserErrors.tooFewShorthandAttributeValues(token, values)
        }
        if values.count > max {
            throw CSSParserErrors.tooManyShorthandAttributeValues(token, values)
        }
        
        for value in values {
            guard case .number = value else {
                throw CSSParserErrors.invalidShorthandAttributeValue(token, value)
            }
        }
    }
    
    class func expandAnchoredPosition(attributeToken token: CSSToken, values: [CSSValue]) throws -> [String:[CSSValue]] {
        try validateAttributeValues(token: token, values: values, min: 2, max: 2)
        return expandAnchoredPositionUnchecked(values: values)
    }
    
    class func expandAnchoredPositionUnchecked(values: [CSSValue]) -> [String:[CSSValue]] {
        return [
            CKUICSSAttributes.anchoredPosition: values,
            CKUICSSAttributes.anchoredPositionX: [ values[0] ],
            CKUICSSAttributes.anchoredPositionY: [ values[1] ]
        ]
    }
    
    class func expandSizeDelta(attributeToken token: CSSToken, values: [CSSValue]) throws -> [String:[CSSValue]] {
        try validateAttributeValues(token: token, values: values, min: 2, max: 2)
        return expandSizeDeltaUnchecked(values: values)
    }
    
    class func expandSizeDeltaUnchecked(values: [CSSValue]) -> [String:[CSSValue]] {
        return [
            CKUICSSAttributes.sizeDelta: values,
            CKUICSSAttributes.sizeDeltaWidth: [ values[0] ],
            CKUICSSAttributes.sizeDeltaHeight: [ values[1] ]
        ]
    }
    
    class func expandAnchors(attributeToken token: CSSToken, values: [CSSValue]) throws -> [String:[CSSValue]] {
        try validateAttributeValues(token: token, values: values, min: 2, max: 4)
        guard let expandedAnchors = expandAnchorsUnchecked(values: values) else {
            throw CSSParserErrors.invalidAttributeValue(token, values[2])
        }
        return expandedAnchors
    }
    
    class func expandAnchorsUnchecked(values: [CSSValue]) -> [String:[CSSValue]]? {
        switch values.count {
        case 2:
            return [
                CKUICSSAttributes.anchors: [ values[0], values[0], values[1], values[1] ],
                CKUICSSAttributes.anchorsXMin: [ values[0] ],
                CKUICSSAttributes.anchorsXMax: [ values[0] ],
                CKUICSSAttributes.anchorsYMin: [ values[1] ],
                CKUICSSAttributes.anchorsYMax: [ values[1] ]
            ]
        case 4:
            return [
                CKUICSSAttributes.anchors: values,
                CKUICSSAttributes.anchorsXMin: [ values[0] ],
                CKUICSSAttributes.anchorsXMax: [ values[1] ],
                CKUICSSAttributes.anchorsYMin: [ values[2] ],
                CKUICSSAttributes.anchorsYMax: [ values[3] ]
            ]
        default:
            return nil
        }
    }
    
    class func expandPivot(attributeToken token: CSSToken, values: [CSSValue]) throws -> [String:[CSSValue]] {
        try validateAttributeValues(token: token, values: values, min: 2, max: 2)
        return expandPivotUnchecked(values: values)
    }
    
    class func expandPivotUnchecked(values: [CSSValue]) -> [String:[CSSValue]] {
        return [
            CKUICSSAttributes.pivot: values,
            CKUICSSAttributes.pivotX: [ values[0] ],
            CKUICSSAttributes.pivotY: [ values[1] ]
        ]
    }
    
}
