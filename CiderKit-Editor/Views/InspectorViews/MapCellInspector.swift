import CiderKit_Engine
import AppKit

class MapCellInspector: BaseTypedInspectorView<EditorMapCellComponent> {

    private let regionField: NSTextField
    private let xField: NSTextField
    private let yField: NSTextField
    private let elevationField: NSTextField
    
    init() {
        let boldFont = NSFont.boldSystemFont(ofSize: 0)
        
        regionField = NSTextField(labelWithString: "")
        regionField.font = boldFont
        xField = NSTextField(labelWithString: "")
        xField.font = boldFont
        yField = NSTextField(labelWithString: "")
        yField.font = boldFont
        elevationField = NSTextField(labelWithString: "")
        elevationField.font = boldFont
        
        let regionLabel = NSTextField(labelWithString: "Region")
        let xLabel = NSTextField(labelWithString: "X")
        let yLabel = NSTextField(labelWithString: "Y")
        let elevationLabel = NSTextField(labelWithString: "Elevation")
        
        let regionStack = NSStackView(views: [regionLabel, regionField])
        let xStack = NSStackView(views: [xLabel, xField])
        let yStack = NSStackView(views: [yLabel, yField])
        let elevationStack = NSStackView(views: [elevationLabel, elevationField])

        super.init(stackedViews: [
            regionStack,
            VSpacer(),
            xStack,
            yStack,
            VSpacer(),
            elevationStack
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateContent() {
        super.updateContent()
        
        if let inspectedObject {
            regionField.stringValue = inspectedObject.region?.id.description ?? "N/A"

            xField.stringValue = inspectedObject.position.x.description
            yField.stringValue = inspectedObject.position.y.description

            elevationField.stringValue = inspectedObject.position.elevation?.description ?? "N/A"
        }
    }
    
}
