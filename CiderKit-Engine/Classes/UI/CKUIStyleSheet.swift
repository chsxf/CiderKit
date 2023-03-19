import CiderCSSKit

public final class CKUIStyleSheet {
    
    private var rules: [CSSRules] = []
    
    public init(contentsOf url: URL) throws {
        try addStyleSheet(contentsOf: url)
    }
    
    public init(styleSheet: String) throws {
        try addStyleSheet(styleSheet: styleSheet)
    }
    
    public func addStyleSheet(contentsOf url: URL) throws {
        let styleSheet = try String(contentsOf: url)
        try addStyleSheet(styleSheet: styleSheet)
    }
    
    public func addStyleSheet(styleSheet: String) throws {
        let cssRules = try CSSParser.parse(buffer: styleSheet, validationConfiguration: CKUICSSValidationConfiguration.default)
        if let last = rules.last {
            cssRules.chainedLowerPriorityRules = last
        }
        rules.append(cssRules)
    }
    
    public func getValue(with attribute: String, for consumer: CSSConsumer) -> [CSSValue]? {
        rules.last!.getValue(with: attribute, for: consumer)
    }
    
    public func getAllValues(for consumer: CSSConsumer) -> [String: [CSSValue]] {
        rules.last!.getAllValues(for: consumer)
    }
    
}
