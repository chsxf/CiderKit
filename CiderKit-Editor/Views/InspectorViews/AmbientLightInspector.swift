import AppKit
import CiderKit_Engine

class AmbientLightInspector: BaseTypedInspectorView<BaseLight>, LabelledColorWellDelegate {

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
        if let inspectedObject {
            isEditing = true
            inspectedObject.color = color.toRGB()!
            isEditing = false
        }
    }
    
}
