import CiderKit_Engine
import AppKit

class SpriteAssetInspector: BaseInspectorView {
    
    private let databaseField: NSTextField
    private let assetNameField: NSTextField
    private let assetUUIDField: NSTextField
    
    init() {
        databaseField = NSTextField(labelWithString: "Database Name")
        assetNameField = NSTextField(labelWithString: "Asset Name")
        assetUUIDField = NSTextField(labelWithString: "Asset UUID")
        
        super.init(stackedViews: [
            InspectorHeader(title: "Asset Database"),
            databaseField,
            InspectorHeader(title: "Asset Name / UUID"),
            assetNameField,
            assetUUIDField
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateContent() {
        super.updateContent()
        
        if let placement = observableObject as? SpriteAssetPlacement {
            let locator = placement.spriteAssetLocator
            
            databaseField.stringValue = locator.databaseKey
            
            let uuidDescription = locator.assetUUID.description
            assetUUIDField.stringValue = uuidDescription
            assetUUIDField.toolTip = uuidDescription
            
            if let assetDescription = locator.assetDescription {
                assetNameField.stringValue = assetDescription.name
            }
            else {
                assetNameField.stringValue = "(Asset not available)"
            }
        }
    }
    
}
