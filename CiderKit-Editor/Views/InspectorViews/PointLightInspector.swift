import CiderKit_Engine
import AppKit

class PointLightInspector: BaseInspectorView, FloatFieldDelegate, NSTextFieldDelegate, LabelledColorWellDelegate {
    
    private let enabledCheckbox: NSButton
    private let colorWell: LabelledColorWell
    
    private let nameField: NSTextField
    
    private let positionXField: FloatField
    private let positionYField: FloatField
    private let elevationField: FloatField
    
    private let nearFalloffField: FloatField
    private let farFalloffField: FloatField
    private let exponentFalloffField: FloatField
    
    init() {
        enabledCheckbox = NSButton(checkboxWithTitle: "Enabled", target: nil, action: #selector(Self.onEnabledToggled))
        
        colorWell = LabelledColorWell(title: "Color")
        
        nameField = NSTextField(string: "")
        
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
            InspectorHeader(title: "Name"),
            nameField,
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
        
        nameField.delegate = self
        
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
        
        if let pointLight = observableObject as? PointLight {
            enabledCheckbox.state = pointLight.enabled ? .on : .off
            colorWell.color = pointLight.color
            
            nameField.stringValue = pointLight.name
            
            positionXField.value = pointLight.position.x
            positionYField.value = pointLight.position.y
            elevationField.value = pointLight.position.z

            nearFalloffField.value = pointLight.falloff.near
            farFalloffField.value = pointLight.falloff.far
            exponentFalloffField.value = pointLight.falloff.exponent
        }
    }
    
    @objc
    private func onEnabledToggled() {
        if let pointLight = observableObject as? PointLight {
            isEditing = true
            pointLight.enabled = enabledCheckbox.state == .on
            isEditing = false
        }
    }
    
    func floatField(_ field: FloatField, valueChanged newValue: Float) {
        if let pointLight = observableObject as? PointLight {
            isEditing = true
            switch field {
            case positionXField:
                pointLight.position.x = positionXField.value
            case positionYField:
                pointLight.position.y = positionYField.value
            case elevationField:
                pointLight.position.z = elevationField.value
            case nearFalloffField:
                pointLight.falloff.near = nearFalloffField.value
            case farFalloffField:
                pointLight.falloff.far = farFalloffField.value
            case exponentFalloffField:
                pointLight.falloff.exponent = exponentFalloffField.value
            default:
                break
            }
            isEditing = false
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let pointLight = observableObject as? PointLight {
            isEditing = true
            pointLight.name = nameField.stringValue
            isEditing = false
        }
    }
    
    func labelledColorWell(_ colorWell: LabelledColorWell, colorChanged color: CGColor) {
        if let pointLight = observableObject as? PointLight {
            isEditing = true
            pointLight.color = colorWell.color
            isEditing = false
        }
    }
    
}
