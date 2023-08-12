import CiderCSSKit

public class CKUICSSValidationConfiguration: CSSValidationConfiguration {
    
    static let `default`: CKUICSSValidationConfiguration = CKUICSSValidationConfiguration()
    
    #if os(watchOS)
    private static let sansSerifFontName = "SF Compact"
    #else
    private static let sansSerifFontName = "SF Pro"
    #endif
    
    public static let fontFamilyByKeyword: [String: String] = [
        "sans-serif": sansSerifFontName,
        "serif": "Times New Roman",
        "monospace": "SF Mono"
    ]
    
    public override var valueGroupingTypeByAttribute: [String:CSSValueGroupingType] {
        var parentDict = super.valueGroupingTypeByAttribute
        parentDict[CKUICSSAttributes.anchoredPosition] = .multiple([.length()], min: 2, max: 2)
        parentDict[CKUICSSAttributes.anchors] = .multiple([
            .percentage,
            .keyword("bottom", associatedValue: .percentage(0)),
            .keyword("center", associatedValue: .percentage(50)),
            .keyword("left", associatedValue: .percentage(0)),
            .keyword("right", associatedValue: .percentage(100)),
            .keyword("top", associatedValue: .percentage(100))
        ], min: 2, max: 4, customExpansionMethod: CKUICSSAttributeExpanders.expandAnchors(attributeToken:values:))
        parentDict[CKUICSSAttributes.sizeDelta] = .multiple([.length()], min: 2, max: 2)
        return parentDict
    }
    
}
