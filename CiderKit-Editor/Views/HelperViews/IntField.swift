import AppKit

protocol IntFieldDelegate: AnyObject {
    
    func intField(_ field: IntField, valueChanged newValue: Int)
    
}

class IntField: NSView, NSTextFieldDelegate {
    
    private let field: NSTextField
    private let stepper: NSStepper
    
    var value: Int {
        get { stepper.integerValue }
        set {
            stepper.integerValue = newValue
            field.integerValue = newValue
        }
    }
    
    var isEnabled: Bool {
        get { stepper.isEnabled }
        set {
            stepper.isEnabled = newValue
            field.isEnabled = newValue
        }
    }
    
    weak var delegate: IntFieldDelegate? = nil
    
    init(title: String, value: Int = 0, minValue: Int = Int.min, maxValue: Int = Int.max, step: Int = 1) {
        let formatter = NumberFormatter()
        formatter.format = "###0"
        formatter.maximumFractionDigits = 0
        
        field = NSTextField()
        field.formatter = formatter
        field.integerValue = value
        
        stepper = NSStepper()
        stepper.integerValue = value
        stepper.minValue = Double(minValue)
        stepper.maxValue = Double(maxValue)
        stepper.increment = Double(step)
        stepper.valueWraps = false
        stepper.action = #selector(Self.stepperValueDidChange(_:))
        
        super.init(frame: NSZeroRect)
        
        field.delegate = self
        stepper.target = self
        
        let stack = NSStackView(views: [NSTextField(labelWithString: title), field, stepper])
        addSubview(stack)
        
        addConstraints([
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: stack, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: stack, attribute: .width, multiplier: 1, constant: 0)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func stepperValueDidChange(_ obj: NSStepper) {
        field.integerValue = stepper.integerValue
        delegate?.intField(self, valueChanged: stepper.integerValue)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if field.integerValue != stepper.integerValue {
            stepper.integerValue = field.integerValue
            delegate?.intField(self, valueChanged: stepper.integerValue)
        }
    }
    
}
