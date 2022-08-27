import AppKit
import CiderKit_Engine

class AmbientLightInspector: BaseInspectorView, LabelledColorWellDelegate {
    
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
        
        if let lightDescription = observableObject as? BaseLight {
            colorWell.color = lightDescription.color
        }
    }
    
    func labelledColorWell(_ colorWell: LabelledColorWell, colorChanged color: CGColor) {
        if let lightDescription = observableObject as? BaseLight {
            isEditing = true
            lightDescription.color = color
            isEditing = false
        }
    }
    
}
