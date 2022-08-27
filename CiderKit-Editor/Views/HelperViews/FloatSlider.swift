import AppKit

protocol FloatSliderDelegate: AnyObject {
    
    func floatSlider(_ slider: FloatSlider, valueChanged newValue: Float)
    
}

class FloatSlider: NSView {
    
    private let slider: NSSlider
    private let valueLabel: NSTextField
    
    var value: Float {
        get { slider.floatValue }
        set {
            slider.floatValue = newValue
            valueLabel.floatValue = newValue
        }
    }
    
    var isEnabled: Bool {
        get { slider.isEnabled }
        set {
            slider.isEnabled = newValue
            valueLabel.isEnabled = newValue
        }
    }
    
    weak var delegate: FloatSliderDelegate? = nil
    
    init(title: String, value: Float = 0, minValue: Float = 0, maxValue: Float = 1) {
        slider = NSSlider(value: Double(value), minValue: Double(minValue), maxValue: Double(maxValue), target: nil, action: #selector(Self.onValueChanged))
        slider.sliderType = .linear
        slider.isVertical = false
        
        valueLabel = NSTextField(labelWithString: "")
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = 3
        valueLabel.formatter = formatter
        valueLabel.floatValue = value
        
        super.init(frame: NSZeroRect)
        
        slider.target = self
        
        let stack = NSStackView(views: [NSTextField(labelWithString: title), slider, valueLabel])
        addSubview(stack)
        
        addConstraints([
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: stack, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: stack, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: valueLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 35)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func onValueChanged() {
        delegate?.floatSlider(self, valueChanged: slider.floatValue)
        valueLabel.floatValue = slider.floatValue
    }
    
}
