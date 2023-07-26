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
    
    init(xmlElement: XMLElement?) {
        var propertiesBuffer: [String: [CSSValue]] = [:]
        if let xmlElement {
            let properties = xmlElement.elements(forName: "property")
            for property in properties {
                let name = property.attribute(forName: "name")!.stringValue!
                let value = property.attribute(forName: "value")!.stringValue!
                let parsedValues = try! CSSParser.parse(attributeName: name, attributeValue: value, validationConfiguration: CKUICSSValidationConfiguration.default)
                propertiesBuffer[name] = parsedValues
            }
        }
        styleProperties = propertiesBuffer
    }
    
}
