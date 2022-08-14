import AppKit
import CiderKit_Engine

class AmbientLightInspector: BaseInspectorView {
    
    private let colorWell: NSColorWell
    
    init() {
        colorWell = NSColorWell(frame: NSZeroRect)
        
        let label = NSTextField(labelWithString: "Color")
        let colorRow = NSStackView(views: [label, colorWell])
        
        super.init(stackedViews: [colorRow])
        
        colorWell.addObserver(self, forKeyPath: "color", context: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateContent() {
        super.updateContent()
        
        if let lightDescription = observableObject as? BaseLight {
            colorWell.color = NSColor(cgColor: lightDescription.color)!
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if
            let lightDescription = observableObject as? BaseLight,
            let keyPath = keyPath,
            keyPath == "color",
            colorWell.isActive
        {
            isEditing = true
            lightDescription.color = colorWell.color.cgColor
            isEditing = false
        }
    }
    
}
