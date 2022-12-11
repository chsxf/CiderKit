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
    
    private let assetXPositionField: FloatField
    private let assetYPositionField: FloatField
    private let assetZPositionField: FloatField
    private let assetXSizeField: FloatField
    private let assetYSizeField: FloatField
    private let assetZSizeField: FloatField
    
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
    
    private let spriteAssetViews: [NSView]
    private let spriteAssetElementViews: [NSView]
    
    init(assetDescription: SpriteAssetDescription, element: SpriteAssetElement) {
        self.assetDescription = assetDescription
        self.element = element
        
        assetXPositionField = FloatField(title: "X", step: 0.1)
        assetYPositionField = FloatField(title: "Y", step: 0.1)
        assetZPositionField = FloatField(title: "Z", step: 0.2)
        
        assetXSizeField = FloatField(title: "X", step: 0.1)
        assetYSizeField = FloatField(title: "Y", step: 0.1)
        assetZSizeField = FloatField(title: "Z", step: 0.2)
        
        spriteAssetViews = [
            InspectorHeader(title: "Asset Position"), assetXPositionField, assetYPositionField, assetZPositionField,
            VSpacer(),
            InspectorHeader(title: "Asset Size"), assetXSizeField, assetYSizeField, assetZSizeField
        ]
        
        nameField = NSTextField(string: "")

        visibleCheckbox = NSButton(checkboxWithTitle: "Visible", target: nil, action: #selector(Self.visibleCheckboxClicked))

        xOffsetField = FloatField(title: "X", step: 1)
        yOffsetField = FloatField(title: "Y", step: 1)

        rotationField = FloatField(title: "Rotation", step: 1)

        xScaleField = FloatField(title: "X", step: 1)
        yScaleField = FloatField(title: "Y", step: 1)
        
        colorWell = LabelledColorWell(title: "Color")
        colorBlendField = FloatSlider(title: "Color Blend")

        spriteField = NSTextField(string: "None")
        spriteField.isEditable = false
        spriteField.isBezeled = true
        selectSpriteButton = NSButton(title: "Select sprite...", target: nil, action: #selector(Self.selectSprite))
        removeSpriteButton = NSButton(title: "Remove", target: nil, action: #selector(Self.removeSprite))
        let buttonRow = NSStackView(views: [selectSpriteButton, removeSpriteButton])
        buttonRow.orientation = .horizontal
        
        spriteAssetElementViews = [
            InspectorHeader(title: "Element Name"), nameField,
            VSpacer(), visibleCheckbox,
            VSpacer(), InspectorHeader(title: "Offset"), xOffsetField, yOffsetField,
            VSpacer(), rotationField,
            VSpacer(), InspectorHeader(title: "Scale"), xScaleField, yScaleField,
            VSpacer(), colorWell, colorBlendField,
            VSpacer(), InspectorHeader(title: "Sprite"), spriteField, buttonRow
        ]
        
        super.init(frame: NSZeroRect)
        
        assetXPositionField.delegate = self
        assetYPositionField.delegate = self
        assetZPositionField.delegate = self
        
        assetXSizeField.delegate = self
        assetYSizeField.delegate = self
        assetZSizeField.delegate = self
        
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
        
        let stackedViews = spriteAssetViews + spriteAssetElementViews
        setViews(stackedViews, in: .leading)
        
        updateForCurrentElement()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateForCurrentElement() {
        if let element, let assetDescription, let animationControlDelegate {
            let animationData = assetDescription.getAnimationData(for: element.uuid, in: animationControlDelegate.currentAnimationState, at: animationControlDelegate.currentAnimationFrame)

            spriteAssetViews.forEach { $0.isHidden = !element.isRoot }
            spriteAssetElementViews.forEach { $0.isHidden = element.isRoot }
            
            if element.isRoot {
                assetXPositionField.value = assetDescription.position.x
                assetYPositionField.value = assetDescription.position.y
                assetZPositionField.value = assetDescription.position.z
                
                assetXSizeField.value = assetDescription.size.x
                assetYSizeField.value = assetDescription.size.y
                assetZSizeField.value = assetDescription.size.z
            }
            else {
                nameField.stringValue = element.name
                visibleCheckbox.state = animationData.elementData.visible ? .on : .off
                xOffsetField.value = Float(animationData.elementData.offset.x)
                yOffsetField.value = Float(animationData.elementData.offset.y)
                rotationField.value = animationData.elementData.rotation.toDegrees()
                xScaleField.value = Float(animationData.elementData.scale.x)
                yScaleField.value = Float(animationData.elementData.scale.y)
                colorWell.color = animationData.elementData.color
                colorBlendField.value = animationData.elementData.colorBlend
                if let spriteLocator = animationData.elementData.spriteLocator {
                    spriteField.stringValue = spriteLocator.description
                    removeSpriteButton.isEnabled = true
                }
                else {
                    spriteField.stringValue = "None"
                    removeSpriteButton.isEnabled = false
                }
            }
        }
        else {
            spriteAssetViews.forEach { $0.isHidden = true }
            spriteAssetElementViews.forEach { $0.isHidden = true }
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
                if let locator = selectorView.getResult() {
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
        case assetXPositionField:
            elementViewDelegate?.elementView(self, assetXPositionChanged: assetXPositionField.value)
            
        case assetYPositionField:
            elementViewDelegate?.elementView(self, assetYPositionChanged: assetYPositionField.value)
            
        case assetZPositionField:
            elementViewDelegate?.elementView(self, assetZPositionChanged: assetZPositionField.value)
            
        case assetXSizeField:
            elementViewDelegate?.elementView(self, assetXSizeChanged: assetXSizeField.value)
            
        case assetYSizeField:
            elementViewDelegate?.elementView(self, assetYSizeChanged: assetYSizeField.value)
            
        case assetZSizeField:
            elementViewDelegate?.elementView(self, assetZSizeChanged: assetZSizeField.value)
            
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
