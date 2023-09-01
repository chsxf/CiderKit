import AppKit

protocol ContextButtonDelegate: AnyObject {

    func contextButtonRequestsMenu(_ button: ContextButton, for event: NSEvent) -> NSMenu?
    
}

class ContextButton: NSButton {
    
    public weak var delegate: ContextButtonDelegate? = nil
    
    public var contextMenu: NSMenu? = nil
    
    override func mouseDown(with event: NSEvent) {
        if let menu = menu(for: event) {
            menu.popUp(positioning: nil, at: frame.origin, in: superview)
        }
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        delegate?.contextButtonRequestsMenu(self, for: event) ?? contextMenu
    }
    
}
