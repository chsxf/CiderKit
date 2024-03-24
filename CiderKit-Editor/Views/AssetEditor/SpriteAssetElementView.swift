import AppKit
import CiderKit_Engine
import CoreGraphics

public class SpriteAssetElementView : TransformAssetElementView, LabelledColorWellDelegate, FloatSliderDelegate {
    
    private let xOffsetField: FloatField
    private let yOffsetField: FloatField
    private let zOffsetField: FloatField

    private let xSizeField: FloatField
    private let ySizeField: FloatField
    private let zSizeField: FloatField

    private let spriteField: NSTextField
    private let selectSpriteButton: NSButton
    private let removeSpriteButton: NSButton
    
    private let xAnchorField: FloatField
    private let yAnchorField: FloatField
    
    private let colorWell: LabelledColorWell
    private let colorBlendField: FloatSlider
    
    required init(assetDescription: AssetDescription, element: TransformAssetElement) {
        xOffsetField = FloatField(title: "X", step: 0.1)
        yOffsetField = FloatField(title: "Y", step: 0.1)
        zOffsetField = FloatField(title: "Z", step: 0.1)
        
        xSizeField = FloatField(title: "X", minValue: 0, step: 0.1)
        ySizeField = FloatField(title: "Y", minValue: 0, step: 0.1)
        zSizeField = FloatField(title: "Z", minValue: 0, step: 0.1)
        
        spriteField = NSTextField(string: "None")
        spriteField.isEditable = false
        spriteField.isBezeled = true
        selectSpriteButton = NSButton(title: "Select sprite...", target: nil, action: #selector(Self.selectSprite))
        removeSpriteButton = NSButton(title: "Remove", target: nil, action: #selector(Self.removeSprite))
        
        xAnchorField = FloatField(title: "X", step: 0.1)
        yAnchorField = FloatField(title: "Y", step: 0.1)
        
        colorWell = LabelledColorWell(title: "Color")
        colorBlendField = FloatSlider(title: "Color Blend")

        super.init(assetDescription: assetDescription, element: element)
        
        xOffsetField.delegate = self
        yOffsetField.delegate = self
        zOffsetField.delegate = self
        
        xSizeField.delegate = self
        ySizeField.delegate = self
        zSizeField.delegate = self
        
        selectSpriteButton.target = self
        removeSpriteButton.target = self

        xAnchorField.delegate = self
        yAnchorField.delegate = self
        
        colorWell.delegate = self
        colorBlendField.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getAdditionalElementViews() -> [NSView] {
        var additionalViews = super.getAdditionalElementViews()
        
        let offsetRow = NSStackView(orientation: .horizontal, views: [xOffsetField, yOffsetField, zOffsetField])
        let sizeRow = NSStackView(orientation: .horizontal, views: [xSizeField, ySizeField, zSizeField])
        let anchorRow = NSStackView(orientation: .horizontal, views: [xAnchorField, yAnchorField])
        
        let buttonRow = NSStackView(orientation: .horizontal, views: [selectSpriteButton, removeSpriteButton])
        
        additionalViews.append(contentsOf: [
            VSpacer(), InspectorHeader(title: "Volume Offset"), offsetRow,
            VSpacer(), InspectorHeader(title: "Volume Size"), sizeRow,
            VSpacer(), InspectorHeader(title: "Sprite"), spriteField, buttonRow,
            VSpacer(), InspectorHeader(title: "Anchor Point"), anchorRow,
            VSpacer(), colorWell, colorBlendField
        ])
        
        return additionalViews
    }
    
    override func updateForCurrentElement(snapshot: AssetElementAnimationSnapshot? = nil) {
        guard let element, let assetDescription, let animationControlDelegate else {
            super.updateForCurrentElement(snapshot: nil)
            return
        }
        
        let animationSnapshot = snapshot ?? assetDescription.getAnimationSnapshot(for: element.uuid, in: animationControlDelegate.currentAnimationName, at: animationControlDelegate.currentAnimationFrame)
        super.updateForCurrentElement(snapshot: animationSnapshot)
        
        if !element.isRoot {
            xOffsetField.value = animationSnapshot.get(trackType: .xVolumeOffset)
            yOffsetField.value = animationSnapshot.get(trackType: .yVolumeOffset)
            zOffsetField.value = animationSnapshot.get(trackType: .zVolumeOffset)
            
            xSizeField.value = animationSnapshot.get(trackType: .xVolumeSize)
            ySizeField.value = animationSnapshot.get(trackType: .yVolumeSize)
            zSizeField.value = animationSnapshot.get(trackType: .zVolumeSize)
            
            if
                let spriteLocatorDescription: String = animationSnapshot.get(trackType: .sprite),
                let spriteLocator: SpriteLocator = SpriteLocator(description: spriteLocatorDescription)
            {
                spriteField.stringValue = spriteLocator.description
                removeSpriteButton.isEnabled = true;
            }
            else {
                spriteField.stringValue = "None"
                removeSpriteButton.isEnabled = false
            }

            xAnchorField.value = animationSnapshot.get(trackType: .xAnchorPoint)
            yAnchorField.value = animationSnapshot.get(trackType: .yAnchorPoint)
            
            colorWell.color = animationSnapshot.get(trackType: .color)
            colorBlendField.value = animationSnapshot.get(trackType: .colorBlendFactor)
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
                if let locator = selectorView.getResult(), let elementViewDelegate = self.elementViewDelegate, let spriteElement = self.element as? SpriteAssetElement {
                    self.spriteField.stringValue = locator.description
                    self.removeSpriteButton.isEnabled = true
                    
                    if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .sprite, for: spriteElement.uuid) {
                        key.set(stringValue: locator.description)
                    }
                    else {
                        spriteElement.spriteLocator = locator
                    }
                    elementViewDelegate.update(element: spriteElement)
                }
            }
        }
    }
    
    @objc
    private func removeSprite() {
        if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
            spriteField.stringValue = "None"
            removeSpriteButton.isEnabled = false
            
            if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .sprite, for: spriteElement.uuid) {
                key.set(stringValue: "")
            }
            else {
                spriteElement.spriteLocator = nil
            }
            elementViewDelegate.update(element: spriteElement)
        }
    }
    
    func labelledColorWell(_ colorWell: LabelledColorWell, colorChanged color: CGColor) {
        if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
            if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .color, for: spriteElement.uuid) {
                key.set(colorValue: color)
            }
            else {
                spriteElement.color = color
            }
            elementViewDelegate.update(element: spriteElement)
        }
    }
    
    func floatSlider(_ slider: FloatSlider, valueChanged newValue: Float) {
        if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
            if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .colorBlendFactor, for: spriteElement.uuid) {
                key.set(floatValue: newValue)
            }
            else {
                spriteElement.colorBlend = newValue
            }
            elementViewDelegate.update(element: spriteElement)
        }
    }
    
    override func floatField(_ field: FloatField, valueChanged newValue: Float) {
        switch field {
        case xOffsetField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .xVolumeOffset, for: spriteElement.uuid) {
                    key.set(floatValue: xOffsetField.value)
                }
                else {
                    spriteElement.volumeOffset.x = xOffsetField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case yOffsetField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .yVolumeOffset, for: spriteElement.uuid) {
                    key.set(floatValue: yOffsetField.value)
                }
                else {
                    spriteElement.volumeOffset.y = yOffsetField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case zOffsetField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .zVolumeOffset, for: spriteElement.uuid) {
                    key.set(floatValue: zOffsetField.value)
                }
                else {
                    spriteElement.volumeOffset.z = zOffsetField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case xSizeField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .xVolumeSize, for: spriteElement.uuid) {
                    key.set(floatValue: xSizeField.value)
                }
                else {
                    spriteElement.volumeSize.x = xSizeField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case ySizeField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .yVolumeSize, for: spriteElement.uuid) {
                    key.set(floatValue: ySizeField.value)
                }
                else {
                    spriteElement.volumeSize.y = ySizeField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case zSizeField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .zVolumeSize, for: spriteElement.uuid) {
                    key.set(floatValue: zSizeField.value)
                }
                else {
                    spriteElement.volumeSize.z = zSizeField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case xAnchorField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .xAnchorPoint, for: spriteElement.uuid) {
                    key.set(floatValue: xAnchorField.value)
                }
                else {
                    spriteElement.anchorPoint.x = CGFloat(xAnchorField.value)
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case yAnchorField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .yAnchorPoint, for: spriteElement.uuid) {
                    key.set(floatValue: yAnchorField.value)
                }
                else {
                    spriteElement.anchorPoint.y = CGFloat(yAnchorField.value)
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        default:
            super.floatField(field, valueChanged: newValue)
        }
    }
    
}
