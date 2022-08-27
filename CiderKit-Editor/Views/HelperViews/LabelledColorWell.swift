import AppKit

protocol LabelledColorWellDelegate: AnyObject {
    
    func labelledColorWell(_ colorWell: LabelledColorWell, colorChanged color: CGColor)
    
}

class LabelledColorWell: NSView {
    
    private let colorWell: NSColorWell
    
    var color: CGColor {
        get { colorWell.color.cgColor }
        set { colorWell.color = NSColor(cgColor: newValue)! }
    }
    
    var isEnabled: Bool {
        get { colorWell.isEnabled }
        set { colorWell.isEnabled = newValue }
    }
    
    weak var delegate: LabelledColorWellDelegate? = nil
    
    init(title: String) {
        colorWell = NSColorWell(frame: NSZeroRect)
        
        super.init(frame: NSZeroRect)
        
        colorWell.addObserver(self, forKeyPath: "color", context: nil)
        
        let label = NSTextField(labelWithString: title)
        
        let stack = NSStackView(views: [label, colorWell])
        addSubview(stack)
        
        addConstraints([
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: stack, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: stack, attribute: .width, multiplier: 1, constant: 0)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, keyPath == "color", colorWell.isActive {
            delegate?.labelledColorWell(self, colorChanged: colorWell.color.cgColor)
        }
    }
    
}
