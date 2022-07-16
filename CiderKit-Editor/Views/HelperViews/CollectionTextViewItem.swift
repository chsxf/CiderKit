import AppKit
import CiderKit_Engine

extension NSUserInterfaceItemIdentifier {
   
    static let textViewItem = NSUserInterfaceItemIdentifier(rawValue: "textViewItem")
    
}

class CollectionTextViewItem: NSCollectionViewItem {
    
    let label = NSTextField(labelWithString: "")
    
    override var isSelected: Bool {
        get { super.isSelected }
        set {
            super.isSelected = newValue
            
            label.backgroundColor = newValue ? NSColor.controlAccentColor : NSColor.clear
            label.drawsBackground = newValue
        }
    }
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        
        textField = label
    }
    
    override func loadView() {
        self.view = label
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
