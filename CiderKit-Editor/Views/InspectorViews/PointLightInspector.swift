import CiderKit_Engine
import AppKit

class PointLightInspector: BaseNamedInspectorView<PointLight>, FloatFieldDelegate, LabelledColorWellDelegate {

    private let enabledCheckbox: NSButton
    private let colorWell: LabelledColorWell
    
    private let positionXField: FloatField
    private let positionYField: FloatField
    private let elevationField: FloatField
    
    private let nearFalloffField: FloatField
    private let farFalloffField: FloatField
    private let exponentFalloffField: FloatField
    
    init() {
        enabledCheckbox = NSButton(checkboxWithTitle: "Enabled", target: nil, action: #selector(Self.onEnabledToggled))
        
        colorWell = LabelledColorWell(title: "Color")
        
        positionXField = FloatField(title: "X")
        positionYField = FloatField(title: "Y")
        elevationField = FloatField(title: "E")
        
        nearFalloffField = FloatField(title: "Near", minValue: 0)
        farFalloffField = FloatField(title: "Far", minValue: 0)
        exponentFalloffField = FloatField(title: "Exp", minValue: -1)
        
        super.init(stackedViews: [
            enabledCheckbox,
            VSpacer(),
            colorWell,
            VSpacer(),
            InspectorHeader(title: "Position"),
            positionXField,
            positionYField,
            elevationField,
            VSpacer(),
            InspectorHeader(title: "Falloff"),
            nearFalloffField,
            farFalloffField,
            exponentFalloffField
        ])
        
        enabledCheckbox.target = self
        
        colorWell.delegate = self
        
        positionXField.delegate = self
        positionYField.delegate = self
        elevationField.delegate = self
        
        nearFalloffField.delegate = self
        farFalloffField.delegate = self
        exponentFalloffField.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateContent() {
        super.updateContent()
        
        if let inspectedObject {
            enabledCheckbox.state = inspectedObject.enabled ? .on : .off
            colorWell.color = inspectedObject.color

            positionXField.value = inspectedObject.position.x
            positionYField.value = inspectedObject.position.y
            elevationField.value = inspectedObject.position.z

            nearFalloffField.value = inspectedObject.falloff.near
            farFalloffField.value = inspectedObject.falloff.far
            exponentFalloffField.value = inspectedObject.falloff.exponent
        }
    }
    
    @objc
    private func onEnabledToggled() {
        if let inspectedObject {
            isEditing = true
            inspectedObject.enabled = enabledCheckbox.state == .on
            isEditing = false
        }
    }
    
    func floatField(_ field: FloatField, valueChanged newValue: Float) {
        if let inspectedObject {
            isEditing = true
            switch field {
            case positionXField:
                inspectedObject.position.x = positionXField.value
            case positionYField:
                inspectedObject.position.y = positionYField.value
            case elevationField:
                inspectedObject.position.z = elevationField.value
            case nearFalloffField:
                inspectedObject.falloff.near = nearFalloffField.value
            case farFalloffField:
                inspectedObject.falloff.far = farFalloffField.value
            case exponentFalloffField:
                inspectedObject.falloff.exponent = exponentFalloffField.value
            default:
                break
            }
            isEditing = false
        }
    }
    
    func labelledColorWell(_ colorWell: LabelledColorWell, colorChanged color: CGColor) {
        if let inspectedObject {
            isEditing = true
            inspectedObject.color = colorWell.color.toRGB()!
            isEditing = false
        }
    }
    
}
