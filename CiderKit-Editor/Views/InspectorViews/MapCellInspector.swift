import CiderKit_Engine
import AppKit

class MapCellInspector: BaseInspectorView {
    
    private let regionField: NSTextField
    private let mapXField: NSTextField
    private let mapYField: NSTextField
    private let elevationField: NSTextField
    
    init() {
        let boldFont = NSFont.boldSystemFont(ofSize: 0)
        
        regionField = NSTextField(labelWithString: "")
        regionField.font = boldFont
        mapXField = NSTextField(labelWithString: "")
        mapXField.font = boldFont
        mapYField = NSTextField(labelWithString: "")
        mapYField.font = boldFont
        elevationField = NSTextField(labelWithString: "")
        elevationField.font = boldFont
        
        let regionLabel = NSTextField(labelWithString: "Region")
        let mapXLabel = NSTextField(labelWithString: "X")
        let mapYLabel = NSTextField(labelWithString: "Y")
        let elevationLabel = NSTextField(labelWithString: "Elevation")
        
        let regionStack = NSStackView(views: [regionLabel, regionField])
        let mapXStack = NSStackView(views: [mapXLabel, mapXField])
        let mapYStack = NSStackView(views: [mapYLabel, mapYField])
        let elevationStack = NSStackView(views: [elevationLabel, elevationField])

        super.init(stackedViews: [
            regionStack,
            VSpacer(),
            mapXStack,
            mapYStack,
            VSpacer(),
            elevationStack
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateContent() {
        super.updateContent()
        
        if let mapCell = observableObject as? MapCellComponent {
            regionField.stringValue = mapCell.region?.id.description ?? "N/A"
            
            mapXField.stringValue = mapCell.mapX.description
            mapYField.stringValue = mapCell.mapY.description
            
            elevationField.stringValue = mapCell.elevation?.description ?? "N/A"
        }
    }
    
}
