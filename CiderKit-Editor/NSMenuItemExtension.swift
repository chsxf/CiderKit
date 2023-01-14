import AppKit

extension NSMenuItem {
    
    convenience init(title: String, target: AnyObject?, action selector: Selector?, keyEquivalent: String) {
        self.init(title: title, action: selector, keyEquivalent: keyEquivalent)
        self.target = target
    }
    
}
