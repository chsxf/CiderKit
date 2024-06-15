import CiderKit_Engine
import AppKit

public class TransformAssetElementView : NSStackView, NSTextFieldDelegate, FloatFieldDelegate, IntFieldDelegate {
    
    weak var assetDescription: AssetDescription? = nil
    
    weak var element: TransformAssetElement? = nil {
        didSet {
            updateForCurrentElement()
        }
    }
    
    weak var elementViewDelegate: AssetElementViewDelegate? = nil
    
    weak var animationControlDelegate: AssetAnimationControlDelegate? = nil {
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
    
    private let assetWFootprint: IntField
    private let assetHFootprint: IntField
    
    private let xWorldOffsetField: FloatField
    private let yWorldOffsetField: FloatField
    private let zWorldOffsetField: FloatField
    private let worldOffsetRow: NSStackView
    private let horizontallyFlippedCheckbox: NSButton

    private let nameField: NSTextField
    private let visibleCheckbox: NSButton
    
    private let assetViews: [NSView]
    private var assetElementViews: [NSView]
    
    required init(assetDescription: AssetDescription, element: TransformAssetElement) {
        self.assetDescription = assetDescription
        self.element = element
        
        assetXPositionField = FloatField(title: "X", step: 0.1)
        assetYPositionField = FloatField(title: "Y", step: 0.1)
        assetZPositionField = FloatField(title: "Z", step: 0.1)
        
        assetWFootprint = IntField(title: "W", minValue: 1)
        assetHFootprint = IntField(title: "H", minValue: 1)
        
        xWorldOffsetField = FloatField(title: "X", step: 0.1)
        yWorldOffsetField = FloatField(title: "Y", step: 0.1)
        zWorldOffsetField = FloatField(title: "Z", step: 0.1)
        
        horizontallyFlippedCheckbox = NSButton(checkboxWithTitle: "Horizontally Flipped", target: nil, action: #selector(Self.horizontallyFlippedCheckboxClicked))

        assetViews = [
            InspectorHeader(title: "Asset Position"), assetXPositionField, assetYPositionField, assetZPositionField,
            VSpacer(),
            InspectorHeader(title: "Footprint"), assetWFootprint, assetHFootprint
        ]
        
        nameField = NSTextField(string: "")

        visibleCheckbox = NSButton(checkboxWithTitle: "Visible", target: nil, action: #selector(Self.visibleCheckboxClicked))

        worldOffsetRow = NSStackView(orientation: .horizontal, views: [xWorldOffsetField, yWorldOffsetField, zWorldOffsetField])
        assetElementViews = [
            InspectorHeader(title: "Element Name"), nameField,
            VSpacer(), visibleCheckbox,
            VSpacer(), InspectorHeader(title: "World Offset"), worldOffsetRow, horizontallyFlippedCheckbox
        ]
        
        super.init(frame: NSZeroRect)
        
        assetElementViews.append(contentsOf: getAdditionalElementViews())
        
        assetXPositionField.delegate = self
        assetYPositionField.delegate = self
        assetZPositionField.delegate = self
        
        assetHFootprint.delegate = self
        assetWFootprint.delegate = self
        
        xWorldOffsetField.delegate = self
        yWorldOffsetField.delegate = self
        zWorldOffsetField.delegate = self
        horizontallyFlippedCheckbox.target = self
        
        nameField.delegate = self

        visibleCheckbox.target = self

        translatesAutoresizingMaskIntoConstraints = false
        
        orientation = .vertical
        alignment = .left
        spacing = 4
        
        let stackedViews = assetViews + assetElementViews
        setViews(stackedViews, in: .leading)
        
        updateForCurrentElement()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getAdditionalElementViews() -> [NSView] { [] }
    
    func updateForCurrentElement(snapshot: AssetElementAnimationSnapshot? = nil) {
        guard let element, let assetDescription, let animationControlDelegate else {
            assetViews.forEach { $0.isHidden = true }
            assetElementViews.forEach { $0.isHidden = true }
            return
        }
        
        let animationSnapshot = snapshot ?? assetDescription.getAnimationSnapshot(for: element.uuid, in: animationControlDelegate.currentAnimationName, at: animationControlDelegate.currentAnimationFrame)
        
        assetViews.forEach { $0.isHidden = !element.isRoot }
        assetElementViews.forEach { $0.isHidden = element.isRoot }
        
        if element.isRoot {
            assetXPositionField.value = assetDescription.position.x
            assetYPositionField.value = assetDescription.position.y
            assetZPositionField.value = assetDescription.position.z
            
            assetWFootprint.value = Int(assetDescription.footprint[0])
            assetHFootprint.value = Int(assetDescription.footprint[1])
        }
        else {
            nameField.stringValue = element.name
            visibleCheckbox.state = animationSnapshot.get(trackType: .visibility) ? .on : .off
            
            xWorldOffsetField.value = animationSnapshot.get(trackType: .xWorldOffset)
            yWorldOffsetField.value = animationSnapshot.get(trackType: .yWorldOffset)
            zWorldOffsetField.value = animationSnapshot.get(trackType: .zWorldOffset)
            horizontallyFlippedCheckbox.state = element.horizontallyFlipped ? .on : .off
        }
    }
    
    @objc
    private func visibleCheckboxClicked() {
        if let elementViewDelegate, let element {
            let visible = visibleCheckbox.state == .on
            if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .visibility, for: element.uuid) {
                key.set(boolValue: visible)
            }
            else {
                element.visible = visible
            }
            elementViewDelegate.update(element: element)
        }
    }
    
    @objc
    private func horizontallyFlippedCheckboxClicked() {
        if let elementViewDelegate, let element {
            element.horizontallyFlipped = horizontallyFlippedCheckbox.state == .on
            elementViewDelegate.update(element: element)
        }
    }
    
    public func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            elementViewDelegate?.elementView(self, nameChanged: textField.stringValue)
        }
    }
    
    func floatField(_ field: FloatField, valueChanged newValue: Float) {
        guard let elementViewDelegate else { return }
        
        switch field {
        case assetXPositionField:
            if let assetDescription {
                assetDescription.rootElement.worldOffset.x = assetXPositionField.value
                elementViewDelegate.update(element: assetDescription.rootElement)
            }
            
        case assetYPositionField:
            if let assetDescription {
                assetDescription.rootElement.worldOffset.y = assetYPositionField.value
                elementViewDelegate.update(element: assetDescription.rootElement)
            }
            
        case assetZPositionField:
            if let assetDescription {
                assetDescription.rootElement.worldOffset.z = assetZPositionField.value
                elementViewDelegate.update(element: assetDescription.rootElement)
            }
            
        case xWorldOffsetField:
            if let element {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .xWorldOffset, for: element.uuid) {
                    key.set(floatValue: xWorldOffsetField.value)
                }
                else {
                    element.worldOffset.x = xWorldOffsetField.value
                }
                elementViewDelegate.update(element: element)
            }

        case yWorldOffsetField:
            if let element {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .yWorldOffset, for: element.uuid) {
                    key.set(floatValue: yWorldOffsetField.value)
                }
                else {
                    element.worldOffset.y = yWorldOffsetField.value
                }
                elementViewDelegate.update(element: element)
            }
            
        case zWorldOffsetField:
            if let element {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .zWorldOffset, for: element.uuid) {
                    key.set(floatValue: zWorldOffsetField.value)
                }
                else {
                    element.worldOffset.z = zWorldOffsetField.value
                }
                elementViewDelegate.update(element: element)
            }

        default:
            break
        }
    }
    
    func intField(_ field: IntField, valueChanged newValue: Int) {
        switch field {
        case assetWFootprint:
            elementViewDelegate?.elementView(self, assetWFootprintChanged: assetWFootprint.value)
            
        case assetHFootprint:
            elementViewDelegate?.elementView(self, assetHFootprintChanged: assetHFootprint.value)
            
        default:
            break
        }
    }
    
    @objc
    private func currentFrameDidChange(_ notif: Notification) {
        updateForCurrentElement()
    }
    
    public final func updateElement() {
        if let element {
            elementViewDelegate?.update(element: element)
        }
    }
    
}
