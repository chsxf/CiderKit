import AppKit
import CiderKit_Engine

class AmbientLightInspector: BaseTypedInspectorView<AmbientLight>, LabelledColorWellDelegate {

    private let colorWell: LabelledColorWell
    
    init() {
        colorWell = LabelledColorWell(title: "Color")
        
        super.init(stackedViews: [colorWell])
        
        colorWell.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateContent() {
        super.updateContent()
        
        if let inspectedObject {
            colorWell.color = inspectedObject.color
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

