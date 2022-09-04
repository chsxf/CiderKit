import AppKit

protocol ContextButtonDelegate: AnyObject {

    func contextButtonRequestsMenu(_ button: ContextButton, for event: NSEvent) -> NSMenu?
    
}

class ContextButton: NSButton {
    
    public weak var delegate: ContextButtonDelegate? = nil
    
    override func mouseDown(with event: NSEvent) {
        if let menu = menu(for: event) {
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        delegate?.contextButtonRequestsMenu(self, for: event)
    }
    
}
