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
        colorWell = NSColorWell()
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: NSZeroRect)
        
        colorWell.addObserver(self, forKeyPath: "color", context: nil)
        
        let label = NSTextField(labelWithString: title)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        addSubview(colorWell)
        
        addConstraints([
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20),
            
            NSLayoutConstraint(item: colorWell, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: colorWell, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.66, constant: 0),
            NSLayoutConstraint(item: colorWell, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
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
