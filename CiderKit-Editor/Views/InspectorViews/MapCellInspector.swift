import CiderKit_Engine
import AppKit

class MapCellInspector: BaseTypedInspectorView<EditorMapCellComponent>, NSTextFieldDelegate {

    private let regionField: NSTextField
    private let nameField: NSTextField
    private let xField: NSTextField
    private let yField: NSTextField
    private let elevationField: NSTextField
    
    init() {
        let boldFont = NSFont.boldSystemFont(ofSize: 0)
        
        regionField = NSTextField(labelWithString: "")
        regionField.font = boldFont
        nameField = NSTextField()
        xField = NSTextField(labelWithString: "")
        xField.font = boldFont
        yField = NSTextField(labelWithString: "")
        yField.font = boldFont
        elevationField = NSTextField(labelWithString: "")
        elevationField.font = boldFont
        
        let regionLabel = NSTextField(labelWithString: "Region")
        let nameLabel = NSTextField(labelWithString: "Name")
        let xLabel = NSTextField(labelWithString: "X")
        let yLabel = NSTextField(labelWithString: "Y")
        let elevationLabel = NSTextField(labelWithString: "Elevation")
        
        let regionStack = NSStackView(views: [regionLabel, regionField])
        let nameStack = NSStackView(views: [nameLabel, nameField])
        let xStack = NSStackView(views: [xLabel, xField])
        let yStack = NSStackView(views: [yLabel, yField])
        let elevationStack = NSStackView(views: [elevationLabel, elevationField])

        super.init(stackedViews: [
            regionStack,
            nameStack,
            VSpacer(),
            xStack,
            yStack,
            VSpacer(),
            elevationStack
        ])

        nameField.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateContent() {
        super.updateContent()
        
        if let inspectedObject {
            regionField.stringValue = inspectedObject.region?.regionModel?.id.description ?? "N/A"

            if let regionModel = inspectedObject.region?.regionModel {
                nameField.stringValue = regionModel.regionDescription.name ?? ""
                nameField.isEditable = true
            }
            else {
                nameField.stringValue = ""
                nameField.isEditable = false
            }

            xField.stringValue = inspectedObject.position.x.description
            yField.stringValue = inspectedObject.position.y.description

            elevationField.stringValue = inspectedObject.position.elevation?.description ?? "N/A"
        }
    }

    func controlTextDidChange(_ obj: Notification) {
        if let inspectedObject, let regionModel = inspectedObject.region?.regionModel {
            isEditing = true
            regionModel.rename(to: nameField.stringValue)
            isEditing = false
            inspectedObject.objectWillChange.send()
        }
    }

}
