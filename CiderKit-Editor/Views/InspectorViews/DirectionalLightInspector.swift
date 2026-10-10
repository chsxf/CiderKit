import CiderKit_Engine
import AppKit

class DirectionalLightInspector: BaseNamedInspectorView<DirectionalLight>, FloatFieldDelegate, LabelledColorWellDelegate {

    private let enabledCheckbox: NSButton
    private let colorWell: LabelledColorWell
    
    private let positionXField: FloatField
    private let positionYField: FloatField
    private let elevationField: FloatField
    
    private let declinationField: FloatField
    private let rightAscensionField: FloatField

    init() {
        enabledCheckbox = NSButton(checkboxWithTitle: "Enabled", target: nil, action: #selector(Self.onEnabledToggled))
        
        colorWell = LabelledColorWell(title: "Color")
        
        positionXField = FloatField(title: "X")
        positionYField = FloatField(title: "Y")
        elevationField = FloatField(title: "E")
        
        declinationField = FloatField(title: "Decl.")
        rightAscensionField = FloatField(title: "RA")

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
            InspectorHeader(title: "Orientation"),
            declinationField,
            rightAscensionField
        ])
        
        enabledCheckbox.target = self
        
        colorWell.delegate = self
        
        positionXField.delegate = self
        positionYField.delegate = self
        elevationField.delegate = self
        
        declinationField.delegate = self
        rightAscensionField.delegate = self
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

            declinationField.value = inspectedObject.orientation.x.toDegrees()
            rightAscensionField.value = inspectedObject.orientation.y.toDegrees()
        }
    }
    
    @objc
    private func onEnabledToggled() {
        if let inspectedObject {
            Task {
                self.isEditing = true
                let newLight = inspectedObject.description.mutated(withEnabled: enabledCheckbox.state == .on)
                await MapModel.shared.update(light: newLight)
                self.isEditing = false
            }
        }
    }
    
    func floatField(_ field: FloatField, valueChanged newValue: Float) {
        if let inspectedObject {
            Task {
                isEditing = true
                var newLight: DirectionalLightDescription? = nil

                switch field {
                case positionXField:
                    newLight = inspectedObject.description.mutated(withPosition: inspectedObject.position.with(x: newValue))
                case positionYField:
                    newLight = inspectedObject.description.mutated(withPosition: inspectedObject.position.with(y: newValue))
                case elevationField:
                    newLight = inspectedObject.description.mutated(withPosition: inspectedObject.position.with(z: newValue))
                case declinationField:
                    var orientation = inspectedObject.orientation
                    orientation.x = declinationField.value.toRadians()
                    newLight = inspectedObject.description.mutated(withOrientation: orientation)
                case rightAscensionField:
                    var orientation = inspectedObject.orientation
                    orientation.y = rightAscensionField.value.toRadians()
                    newLight = inspectedObject.description.mutated(withOrientation: orientation)
                default:
                    break
                }

                if let newLight {
                    await MapModel.shared.update(light: newLight)
                }
                isEditing = false
            }
        }
    }
    
    func labelledColorWell(_ colorWell: LabelledColorWell, colorChanged color: CGColor) {
        if let inspectedObject, let rgbColor = color.toRGB() {
            Task {
                self.isEditing = true
                let newLight = inspectedObject.description.mutated(withColor: rgbColor)
                await MapModel.shared.update(light: newLight)
                self.isEditing = false
            }
        }
    }
    
}
