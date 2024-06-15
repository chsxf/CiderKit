import AppKit
import CiderKit_Engine
import CoreGraphics

public class SpriteAssetElementView : TransformAssetElementView, LabelledColorWellDelegate, FloatSliderDelegate {
    
    private let xWorldOffsetField: FloatField
    private let yWorldOffsetField: FloatField
    private let zWorldOffsetField: FloatField

    private let xWorldSizeField: FloatField
    private let yWorldSizeField: FloatField
    private let zWorldSizeField: FloatField

    private let spriteField: NSTextField
    private let selectSpriteButton: NSButton
    private let removeSpriteButton: NSButton
    
    private let xAnchorField: FloatField
    private let yAnchorField: FloatField
    
    private let colorWell: LabelledColorWell
    private let colorBlendField: FloatSlider
    
    required init(assetDescription: AssetDescription, element: TransformAssetElement) {
        xWorldOffsetField = FloatField(title: "X", step: 0.1)
        yWorldOffsetField = FloatField(title: "Y", step: 0.1)
        zWorldOffsetField = FloatField(title: "Z", step: 0.1)
        
        xWorldSizeField = FloatField(title: "X", minValue: 0, step: 0.1)
        yWorldSizeField = FloatField(title: "Y", minValue: 0, step: 0.1)
        zWorldSizeField = FloatField(title: "Z", minValue: 0, step: 0.1)
        
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
        
        xWorldOffsetField.delegate = self
        yWorldOffsetField.delegate = self
        zWorldOffsetField.delegate = self
        
        xWorldSizeField.delegate = self
        yWorldSizeField.delegate = self
        zWorldSizeField.delegate = self
        
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
        
        let worldOffsetRow = NSStackView(orientation: .horizontal, views: [xWorldOffsetField, yWorldOffsetField, zWorldOffsetField])
        let worldSizeRow = NSStackView(orientation: .horizontal, views: [xWorldSizeField, yWorldSizeField, zWorldSizeField])
        let anchorRow = NSStackView(orientation: .horizontal, views: [xAnchorField, yAnchorField])
        
        let buttonRow = NSStackView(orientation: .horizontal, views: [selectSpriteButton, removeSpriteButton])
        
        additionalViews.append(contentsOf: [
            VSpacer(), InspectorHeader(title: "Volume World Offset"), worldOffsetRow,
            VSpacer(), InspectorHeader(title: "Volume World Size"), worldSizeRow,
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
            xWorldOffsetField.value = animationSnapshot.get(trackType: .xVolumeWorldOffset)
            yWorldOffsetField.value = animationSnapshot.get(trackType: .yVolumeWorldOffset)
            zWorldOffsetField.value = animationSnapshot.get(trackType: .zVolumeWorldOffset)
            
            xWorldSizeField.value = animationSnapshot.get(trackType: .xVolumeWorldSize)
            yWorldSizeField.value = animationSnapshot.get(trackType: .yVolumeWorldSize)
            zWorldSizeField.value = animationSnapshot.get(trackType: .zVolumeWorldSize)
            
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
        case xWorldOffsetField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .xVolumeWorldOffset, for: spriteElement.uuid) {
                    key.set(floatValue: xWorldOffsetField.value)
                }
                else {
                    spriteElement.volumeWorldOffset.x = xWorldOffsetField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case yWorldOffsetField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .yVolumeWorldOffset, for: spriteElement.uuid) {
                    key.set(floatValue: yWorldOffsetField.value)
                }
                else {
                    spriteElement.volumeWorldOffset.y = yWorldOffsetField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case zWorldOffsetField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .zVolumeWorldOffset, for: spriteElement.uuid) {
                    key.set(floatValue: zWorldOffsetField.value)
                }
                else {
                    spriteElement.volumeWorldOffset.z = zWorldOffsetField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case xWorldSizeField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .xVolumeWorldSize, for: spriteElement.uuid) {
                    key.set(floatValue: xWorldSizeField.value)
                }
                else {
                    spriteElement.volumeWorldSize.x = xWorldSizeField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case yWorldSizeField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .yVolumeWorldSize, for: spriteElement.uuid) {
                    key.set(floatValue: yWorldSizeField.value)
                }
                else {
                    spriteElement.volumeWorldSize.y = yWorldSizeField.value
                }
                elementViewDelegate.update(element: spriteElement)
            }
            
        case zWorldSizeField:
            if let elementViewDelegate, let spriteElement = element as? SpriteAssetElement {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .zVolumeWorldSize, for: spriteElement.uuid) {
                    key.set(floatValue: zWorldSizeField.value)
                }
                else {
                    spriteElement.volumeWorldSize.z = zWorldSizeField.value
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
