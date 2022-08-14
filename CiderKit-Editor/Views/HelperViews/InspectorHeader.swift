import AppKit

class InspectorHeader: NSTextField {
    
    init(title: String) {
        super.init(frame: NSZeroRect)
        
        stringValue = title
        textColor = .secondaryLabelColor
        
        isSelectable = false
        isEditable = false
        isBezeled = false
        isBordered = false
        drawsBackground = false
        
        let headerFontSize = NSFont.systemFontSize * 0.9
        font = NSFont.boldSystemFont(ofSize: headerFontSize)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
