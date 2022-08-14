import AppKit

protocol FloatFieldDelegate: AnyObject {
    
    func floatField(_ field: FloatField, valueChanged newValue: Float)
    
}

class FloatField: NSView, NSTextFieldDelegate {
    
    private let field: NSTextField
    private let stepper: NSStepper
    
    var value: Float {
        get { stepper.floatValue }
        set {
            stepper.floatValue = newValue
            field.floatValue = newValue
        }
    }
    
    var isEnabled: Bool {
        get { stepper.isEnabled }
        set {
            stepper.isEnabled = newValue
            field.isEnabled = newValue
        }
    }
    
    weak var delegate: FloatFieldDelegate? = nil
    
    init(title: String, floatValue: Float = 0, minValue: Float = -Float.infinity, maxValue: Float = Float.infinity, step: Float = 0.1) {
        let formatter = NumberFormatter()
        formatter.format = "###0.#####"
        formatter.maximumFractionDigits = 5
        
        field = NSTextField()
        field.formatter = formatter
        field.floatValue = floatValue
        
        stepper = NSStepper()
        stepper.floatValue = floatValue
        stepper.minValue = Double(minValue)
        stepper.maxValue = Double(maxValue)
        stepper.increment = Double(step)
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
        field.floatValue = stepper.floatValue
        delegate?.floatField(self, valueChanged: stepper.floatValue)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if field.floatValue != stepper.floatValue {
            stepper.floatValue = field.floatValue
            delegate?.floatField(self, valueChanged: stepper.floatValue)
        }
    }
    
}
