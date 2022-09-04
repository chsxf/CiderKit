import AppKit

extension NSButton {
    
    convenience init(systemSymbolName: String, accessibilityDescription: String? = nil, target: Any? = nil, action: Selector? = nil) {
        let image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: accessibilityDescription)!
        self.init(image: image, target: target, action: action)
    }
    
    convenience init(title: String, systemSymbolName: String, accessibilityDescription: String? = nil, target: Any? = nil, action: Selector? = nil) {
        let image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: accessibilityDescription)!
        self.init(title: title, target: target, action: action)
        self.image = image
        self.imagePosition = .imageLeading
    }
    
}
