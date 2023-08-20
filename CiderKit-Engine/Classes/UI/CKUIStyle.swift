import CiderCSSKit
import SpriteKit

public class CKUIStyle {
    
    private let styleProperties: [String: [CSSValue]]
    private var overriddenStyleProperties: [String: [CSSValue]] = [:]
    
    subscript(key: String) -> [CSSValue]? {
        get { overriddenStyleProperties[key] ?? styleProperties[key] }
        set { overriddenStyleProperties[key] = newValue }
    }
    
    public init() {
        styleProperties = [:]
    }
    
    public init(attributes: String) {
        styleProperties = try! CSSParser.parse(ruleBlock: attributes, validationConfiguration: CKUICSSValidationConfiguration.default)
    }

    public init(properties: [String: [CSSValue]]) {
        styleProperties = properties
    }
    
}
