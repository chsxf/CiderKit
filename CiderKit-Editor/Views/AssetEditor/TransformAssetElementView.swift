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
    
    private let xOffsetField: FloatField
    private let yOffsetField: FloatField
    private let zOffsetField: FloatField
    private let offsetRow: NSStackView

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
        
        xOffsetField = FloatField(title: "X", step: 0.1)
        yOffsetField = FloatField(title: "Y", step: 0.1)
        zOffsetField = FloatField(title: "Z", step: 0.1)

        assetViews = [
            InspectorHeader(title: "Asset Position"), assetXPositionField, assetYPositionField, assetZPositionField,
            VSpacer(),
            InspectorHeader(title: "Footprint"), assetWFootprint, assetHFootprint
        ]
        
        nameField = NSTextField(string: "")

        visibleCheckbox = NSButton(checkboxWithTitle: "Visible", target: nil, action: #selector(Self.visibleCheckboxClicked))

        offsetRow = NSStackView(orientation: .horizontal, views: [xOffsetField, yOffsetField, zOffsetField])
        assetElementViews = [
            InspectorHeader(title: "Element Name"), nameField,
            VSpacer(), visibleCheckbox,
            VSpacer(), InspectorHeader(title: "Offset"), offsetRow
        ]
        
        super.init(frame: NSZeroRect)
        
        assetElementViews.append(contentsOf: getAdditionalElementViews())
        
        assetXPositionField.delegate = self
        assetYPositionField.delegate = self
        assetZPositionField.delegate = self
        
        assetHFootprint.delegate = self
        assetWFootprint.delegate = self
        
        xOffsetField.delegate = self
        yOffsetField.delegate = self
        zOffsetField.delegate = self
        
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
            
            xOffsetField.value = animationSnapshot.get(trackType: .xOffset)
            yOffsetField.value = animationSnapshot.get(trackType: .yOffset)
            zOffsetField.value = animationSnapshot.get(trackType: .zOffset)
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
            elementViewDelegate.updateElement(element: element)
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
                assetDescription.rootElement.offset.x = assetXPositionField.value
                elementViewDelegate.updateElement(element: assetDescription.rootElement)
            }
            
        case assetYPositionField:
            if let assetDescription {
                assetDescription.rootElement.offset.y = assetYPositionField.value
                elementViewDelegate.updateElement(element: assetDescription.rootElement)
            }
            
        case assetZPositionField:
            if let assetDescription {
                assetDescription.rootElement.offset.z = assetZPositionField.value
                elementViewDelegate.updateElement(element: assetDescription.rootElement)
            }
            
        case xOffsetField:
            if let element {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .xOffset, for: element.uuid) {
                    key.set(floatValue: xOffsetField.value)
                }
                else {
                    element.offset.x = xOffsetField.value
                }
                elementViewDelegate.updateElement(element: element)
            }

        case yOffsetField:
            if let element {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .yOffset, for: element.uuid) {
                    key.set(floatValue: yOffsetField.value)
                }
                else {
                    element.offset.y = yOffsetField.value
                }
                elementViewDelegate.updateElement(element: element)
            }
            
        case zOffsetField:
            if let element {
                if let key = elementViewDelegate.getCurrentAnimationKey(trackType: .zOffset, for: element.uuid) {
                    key.set(floatValue: zOffsetField.value)
                }
                else {
                    element.offset.z = zOffsetField.value
                }
                elementViewDelegate.updateElement(element: element)
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
            elementViewDelegate?.updateElement(element: element)
        }
    }
    
}
