import AppKit
import CiderKit_Engine

class SpriteAssetElementView: NSStackView, NSTextFieldDelegate, FloatFieldDelegate {
    
    weak var element: SpriteAssetElement? = nil {
        didSet {
            updateForCurrentElement()
        }
    }
    
    weak var elementViewDelegate: SpriteAssetElementViewDelegate? = nil
    
    private let nameField: NSTextField
    private let xOffsetField: FloatField
    private let yOffsetField: FloatField
    private let rotationField: FloatField
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
        
        xOffsetField = FloatField(title: "X", step: 1)
        yOffsetField = FloatField(title: "Y", step: 1)
        
        rotationField = FloatField(title: "Rotation", step: 1)
        
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
        yOffsetField.delegate = self
        
        rotationField.delegate = self
        
        selectSpriteButton.target = self
        removeSpriteButton.target = self
        
        translatesAutoresizingMaskIntoConstraints = false
        
        orientation = .vertical
        alignment = .left
        spacing = 4
        
        addArrangedSubview(nameLabel)
        addArrangedSubview(nameField)
        
        addArrangedSubview(VSpacer())
        addArrangedSubview(InspectorHeader(title: "Offset"))
        addArrangedSubview(xOffsetField)
        addArrangedSubview(yOffsetField)
        
        addArrangedSubview(VSpacer())
        addArrangedSubview(rotationField)
        
        addArrangedSubview(VSpacer())
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
            
            nameField.isEnabled = editable
            nameField.stringValue = element.name
            
            let xOffset = Float(element.offset.x)
            xOffsetField.isEnabled = editable
            xOffsetField.value = xOffset
            
            let yOffset = Float(element.offset.y)
            yOffsetField.isEnabled = editable
            yOffsetField.value = yOffset
            
            rotationField.isEnabled = editable
            rotationField.value = element.rotation
            
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
            nameField.isEnabled = false
            
            xOffsetField.value = 0
            xOffsetField.isEnabled = false
            
            yOffsetField.value = 0
            yOffsetField.isEnabled = false
            
            rotationField.value = 0
            rotationField.isEnabled = false
            
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
    
    func floatField(_ field: FloatField, valueChanged newValue: Float) {
        if field === xOffsetField || field === yOffsetField {
            elementViewDelegate?.elementView(self, offsetChanged: CGPoint(x: CGFloat(xOffsetField.value), y: CGFloat(yOffsetField.value)))
        }
        else if field === rotationField {
            elementViewDelegate?.elementView(self, rotationChanged: rotationField.value)
        }
    }
    
}
