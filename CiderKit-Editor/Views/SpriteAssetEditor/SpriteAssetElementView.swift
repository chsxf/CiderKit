import AppKit
import CiderKit_Engine

class SpriteAssetElementView: NSStackView, NSTextFieldDelegate, FloatFieldDelegate, FloatSliderDelegate, LabelledColorWellDelegate {
    
    weak var assetDescription: SpriteAssetDescription? = nil
    
    weak var element: SpriteAssetElement? = nil {
        didSet {
            updateForCurrentElement()
        }
    }
    
    weak var elementViewDelegate: SpriteAssetElementViewDelegate? = nil
    
    weak var animationControlDelegate: SpriteAssetAnimationControlDelegate? = nil {
        didSet {
            if oldValue !== animationControlDelegate {
                NotificationCenter.default.removeObserver(self)
            }
            
            if let animationControlDelegate {
                NotificationCenter.default.addObserver(self, selector: #selector(Self.currentFrameDidChange(_:)), name: .animationCurrentFrameDidChange, object: animationControlDelegate)
                updateForCurrentElement()
            }
        }
    }
    
    private let nameField: NSTextField
    private let visibleCheckbox: NSButton
    private let xOffsetField: FloatField
    private let yOffsetField: FloatField
    private let rotationField: FloatField
    private let xScaleField: FloatField
    private let yScaleField: FloatField
    private let colorWell: LabelledColorWell
    private let colorBlendField: FloatSlider
    private let spriteField: NSTextField
    private let selectSpriteButton: NSButton
    private let removeSpriteButton: NSButton
    
    init(assetDescription: SpriteAssetDescription, element: SpriteAssetElement) {
        self.assetDescription = assetDescription
        self.element = element
        
        let nameLabel = NSTextField(labelWithString: "Name")
        nameField = NSTextField(string: "")

        visibleCheckbox = NSButton(checkboxWithTitle: "Visible", target: nil, action: #selector(Self.visibleCheckboxClicked))

        xOffsetField = FloatField(title: "X", step: 1)
        yOffsetField = FloatField(title: "Y", step: 1)

        rotationField = FloatField(title: "Rotation", step: 1)

        xScaleField = FloatField(title: "X", step: 1)
        yScaleField = FloatField(title: "Y", step: 1)
        
        colorWell = LabelledColorWell(title: "Color")
        colorBlendField = FloatSlider(title: "Color Blend")

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

        visibleCheckbox.target = self

        xOffsetField.delegate = self
        yOffsetField.delegate = self

        rotationField.delegate = self

        xScaleField.delegate = self
        yScaleField.delegate = self

        colorWell.delegate = self
        colorBlendField.delegate = self

        selectSpriteButton.target = self
        removeSpriteButton.target = self
        
        translatesAutoresizingMaskIntoConstraints = false
        
        orientation = .vertical
        alignment = .left
        spacing = 4
        
        let stackedViews = [
            nameLabel, nameField,
            VSpacer(), visibleCheckbox,
            VSpacer(), InspectorHeader(title: "Offset"), xOffsetField, yOffsetField,
            VSpacer(), rotationField,
            VSpacer(), InspectorHeader(title: "Scale"), xScaleField, yScaleField,
            VSpacer(), colorWell, colorBlendField,
            VSpacer(), spriteLabel, spriteField, buttonRow
        ]
        setViews(stackedViews, in: .leading)
        
        updateForCurrentElement()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateForCurrentElement() {
        if let element, let assetDescription, let animationControlDelegate {
            let animationData = assetDescription.getAnimationData(for: element.uuid, in: animationControlDelegate.currentAnimationState, at: animationControlDelegate.currentAnimationFrame)

            let editable = !element.isRoot

            nameField.isEnabled = editable
            nameField.stringValue = element.name

            visibleCheckbox.isEnabled = editable && animationData.isKeyValue(for: .visibility)
            visibleCheckbox.state = animationData.elementData.visible ? .on : .off

            xOffsetField.isEnabled = editable && animationData.isKeyValue(for: .xOffset)
            xOffsetField.value = Float(animationData.elementData.offset.x)

            yOffsetField.isEnabled = editable && animationData.isKeyValue(for: .yOffset)
            yOffsetField.value = Float(animationData.elementData.offset.y)

            rotationField.isEnabled = editable && animationData.isKeyValue(for: .rotation)
            rotationField.value = animationData.elementData.rotation.toDegrees()

            xScaleField.isEnabled = editable && animationData.isKeyValue(for: .xScale)
            xScaleField.value = Float(animationData.elementData.scale.x)

            yScaleField.isEnabled = editable && animationData.isKeyValue(for: .yScale)
            yScaleField.value = Float(animationData.elementData.scale.y)

            colorWell.isEnabled = editable && animationData.isKeyValue(for: .color)
            colorWell.color = animationData.elementData.color

            colorBlendField.isEnabled = editable && animationData.isKeyValue(for: .colorBlendFactor)
            colorBlendField.value = animationData.elementData.colorBlend

            selectSpriteButton.isEnabled = editable && animationData.isKeyValue(for: .sprite)
            if let spriteLocator = animationData.elementData.spriteLocator {
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

            visibleCheckbox.state = .on
            visibleCheckbox.isEnabled = false

            xOffsetField.value = 0
            xOffsetField.isEnabled = false

            yOffsetField.value = 0
            yOffsetField.isEnabled = false

            rotationField.value = 0
            rotationField.isEnabled = false

            xScaleField.value = 0
            xScaleField.isEnabled = false

            yScaleField.value = 0
            yScaleField.isEnabled = false

            colorWell.color = .white
            colorWell.isEnabled = false

            colorBlendField.value = 0
            colorBlendField.isEnabled = false

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
    
    @objc
    private func visibleCheckboxClicked() {
        elementViewDelegate?.elementView(self, visibilityChanged: visibleCheckbox.state == .on)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            elementViewDelegate?.elementView(self, nameChanged: textField.stringValue)
        }
    }
    
    func floatField(_ field: FloatField, valueChanged newValue: Float) {
        switch field {
        case xOffsetField:
            elementViewDelegate?.elementView(self, xOffsetChanged: xOffsetField.value)

        case yOffsetField:
            elementViewDelegate?.elementView(self, yOffsetChanged: yOffsetField.value)

        case rotationField:
            elementViewDelegate?.elementView(self, rotationChanged: rotationField.value.toRadians())

        case xScaleField:
            elementViewDelegate?.elementView(self, xScaleChanged: xScaleField.value)

        case yScaleField:
            elementViewDelegate?.elementView(self, yScaleChanged: yScaleField.value)

        default:
            break
        }
    }
    
    func floatSlider(_ slider: FloatSlider, valueChanged newValue: Float) {
        elementViewDelegate?.elementView(self, colorBlendChanged: newValue)
    }
    
    func labelledColorWell(_ colorWell: LabelledColorWell, colorChanged color: CGColor) {
        elementViewDelegate?.elementView(self, colorChanged: color)
    }
    
    @objc
    private func currentFrameDidChange(_ notif: Notification) {
        updateForCurrentElement()
    }
    
}
