import AppKit
import CiderKit_Engine

class SpriteAssetElementView: NSStackView, NSTextFieldDelegate {
    
    weak var element: SpriteAssetElement? = nil {
        didSet {
            updateForCurrentElement()
        }
    }
    
    weak var elementViewDelegate: SpriteAssetElementViewDelegate? = nil
    
    private let nameField: NSTextField
    private let xOffsetField: NSTextField
    private let xOffsetStepper: NSStepper
    private let yOffsetField: NSTextField
    private let yOffsetStepper: NSStepper
    private let rotationField: NSTextField
    private let rotationStepper: NSStepper
    private let spriteField: NSTextField
    private let selectSpriteButton: NSButton
    private let removeSpriteButton: NSButton
    
    init(element: SpriteAssetElement) {
        self.element = element
        
        let nameLabel = NSTextField(labelWithString: "Name")
        nameField = NSTextField(string: "")
        
        let formatter = NumberFormatter()
        formatter.format = "###0.#####"
        formatter.maximumFractionDigits = 5
        
        let spacer1 = NSTextField(labelWithString: "")
        let offsetLabel = NSTextField(labelWithString: "Offset")
        let xLabel = NSTextField(labelWithString: "X")
        xOffsetField = NSTextField(string: "")
        xOffsetField.formatter = formatter
        xOffsetField.floatValue = 0
        xOffsetStepper = NSStepper()
        xOffsetStepper.floatValue = 0
        xOffsetStepper.maxValue = Double.infinity
        xOffsetStepper.minValue = -Double.infinity
        xOffsetStepper.action = #selector(Self.stepperValueDidChange(_:))
        let xOffsetRow = NSStackView(views: [xOffsetField, xOffsetStepper])
        xOffsetRow.orientation = .horizontal
        let yLabel = NSTextField(labelWithString: "Y")
        yOffsetField = NSTextField(string: "")
        yOffsetField.formatter = formatter
        yOffsetField.floatValue = 0
        yOffsetStepper = NSStepper()
        yOffsetStepper.maxValue = Double.infinity
        yOffsetStepper.minValue = -Double.infinity
        yOffsetStepper.action = #selector(Self.stepperValueDidChange(_:))
        let yOffsetRow = NSStackView(views: [yOffsetField, yOffsetStepper])
        yOffsetRow.orientation = .horizontal
        
        let spacer2 = NSTextField(labelWithString: "")
        let rotationLabel = NSTextField(labelWithString: "Rotation")
        rotationField = NSTextField(string: "")
        rotationField.formatter = formatter
        rotationField.floatValue = 0
        rotationStepper = NSStepper()
        rotationStepper.floatValue = 0
        rotationStepper.maxValue = Double.infinity
        rotationStepper.minValue = -Double.infinity
        rotationStepper.action = #selector(Self.stepperValueDidChange(_:))
        let rotationRow = NSStackView(views: [rotationField, rotationStepper])
        rotationRow.orientation = .horizontal
        
        let spacer3 = NSTextField(labelWithString: "")
        let spriteLabel = NSTextField(labelWithString: "Sprite")
        spriteField = NSTextField(string: "None")
        spriteField.isEditable = false
        spriteField.isBezeled = true
        selectSpriteButton = NSButton(title: "Select sprite...", target: nil, action: #selector(Self.selectSprite))
        removeSpriteButton = NSButton(title: "Remove", target: nil, action: #selector(Self.removeSprite))
        let buttonRow = NSStackView(views: [selectSpriteButton, removeSpriteButton])
        buttonRow.orientation = .horizontal
        
        super.init(frame: NSZeroRect)
        
        nameField.delegate = self
        
        xOffsetField.delegate = self
        xOffsetStepper.target = self
        yOffsetField.delegate = self
        yOffsetStepper.target = self
        
        rotationField.delegate = self
        rotationStepper.target = self
        
        selectSpriteButton.target = self
        removeSpriteButton.target = self
        
        translatesAutoresizingMaskIntoConstraints = false
        
        orientation = .vertical
        alignment = .left
        spacing = 4
        
        addArrangedSubview(nameLabel)
        addArrangedSubview(nameField)
        
        addArrangedSubview(spacer1)
        addArrangedSubview(offsetLabel)
        addArrangedSubview(xLabel)
        addArrangedSubview(xOffsetRow)
        addArrangedSubview(yLabel)
        addArrangedSubview(yOffsetRow)
        
        addArrangedSubview(spacer2)
        addArrangedSubview(rotationLabel)
        addArrangedSubview(rotationRow)
        
        addArrangedSubview(spacer3)
        addArrangedSubview(spriteLabel)
        addArrangedSubview(spriteField)
        addArrangedSubview(buttonRow)
        
        updateForCurrentElement()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateForCurrentElement() {
        if let element = element {
            let editable = !element.isRoot
            
            nameField.isEditable = editable
            nameField.stringValue = element.name
            
            let xOffset = Float(element.offset.x)
            xOffsetField.isEditable = editable
            xOffsetField.floatValue = xOffset
            xOffsetStepper.floatValue = xOffset
            xOffsetStepper.isHidden = !editable
            
            let yOffset = Float(element.offset.y)
            yOffsetField.isEditable = editable
            yOffsetField.floatValue = yOffset
            yOffsetStepper.floatValue = yOffset
            yOffsetStepper.isHidden = !editable
            
            rotationField.isEditable = editable
            rotationField.floatValue = element.rotation
            rotationStepper.floatValue = element.rotation
            rotationStepper.isHidden = !editable
            
            selectSpriteButton.isEnabled = editable
            if let spriteLocator = element.spriteLocator {
                spriteField.stringValue = spriteLocator.description
                removeSpriteButton.isEnabled = true
            }
            else {
                spriteField.stringValue = "None"
                removeSpriteButton.isEnabled = false
            }
        }
        else {
            nameField.stringValue = ""
            nameField.isEditable = false
            
            xOffsetField.floatValue = 0
            xOffsetField.isEditable = false
            xOffsetStepper.isHidden = true
            
            yOffsetField.floatValue = 0
            yOffsetField.isEditable = false
            yOffsetStepper.isHidden = true
            
            rotationField.floatValue = 0
            rotationField.isEditable = false
            rotationStepper.isHidden = true
            
            spriteField.stringValue = "None"
            selectSpriteButton.isEnabled = false
            removeSpriteButton.isEnabled = false
        }
    }
    
    @objc
    private func selectSprite() {
        let windowRect: CGRect = CGRect(x: 0, y: 0, width: 400, height: 600)
        
        let window = NSWindow(contentRect: windowRect, styleMask: [.resizable, .titled], backing: .buffered, defer: false)
        let selectorView = SpriteSelectorView()
        window.contentView = selectorView
        
        self.window?.beginSheet(window) { responseCode in
            if responseCode == .OK {
                if let locator = selectorView.selectedSpriteLocator {
                    self.spriteField.stringValue = locator.description
                    self.removeSpriteButton.isEnabled = true
                    self.elementViewDelegate?.elementView(self, spriteChanged: locator)
                }
            }
        }
    }
    
    @objc
    private func removeSprite() {
        spriteField.stringValue = "None"
        removeSpriteButton.isEnabled = false
        elementViewDelegate?.elementView(self, spriteChanged: nil)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            if textField === nameField {
                elementViewDelegate?.elementView(self, nameChanged: textField.stringValue)
            }
            else if textField === xOffsetField {
                xOffsetStepper.floatValue = xOffsetField.floatValue
                elementViewDelegate?.elementView(self, offsetChanged: CGPoint(x: CGFloat(xOffsetField.floatValue), y: CGFloat(yOffsetField.floatValue)))
            }
            else if textField === yOffsetField {
                yOffsetStepper.floatValue = yOffsetField.floatValue
                elementViewDelegate?.elementView(self, offsetChanged: CGPoint(x: CGFloat(xOffsetField.floatValue), y: CGFloat(yOffsetField.floatValue)))
            }
            else if textField === rotationStepper {
                rotationStepper.floatValue = rotationField.floatValue
                elementViewDelegate?.elementView(self, rotationChanged: rotationField.floatValue)
            }
        }
    }
    
    @objc
    private func stepperValueDidChange(_ obj: NSStepper) {
        if obj === xOffsetStepper {
            xOffsetField.floatValue = xOffsetStepper.floatValue
            elementViewDelegate?.elementView(self, offsetChanged: CGPoint(x: CGFloat(xOffsetField.floatValue), y: CGFloat(yOffsetField.floatValue)))
        }
        else if obj === yOffsetStepper {
            yOffsetField.floatValue = yOffsetStepper.floatValue
            elementViewDelegate?.elementView(self, offsetChanged: CGPoint(x: CGFloat(xOffsetField.floatValue), y: CGFloat(yOffsetField.floatValue)))
        }
        else if obj === rotationStepper {
            rotationField.floatValue = rotationStepper.floatValue
            elementViewDelegate?.elementView(self, rotationChanged: rotationField.floatValue)
        }
    }
    
}
