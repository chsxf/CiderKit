import CiderKit_Engine
import AppKit

class AssetInspector: BaseInspectorView {
    
    private let databaseField: NSTextField
    private let assetNameField: NSTextField
    private let assetUUIDField: NSTextField
    private let horizontallyFlippedCheckbox: NSButton
    private let interactiveCheckbox: NSButton
    
    init() {
        databaseField = NSTextField(labelWithString: "Database Name")
        assetNameField = NSTextField(labelWithString: "Asset Name")
        assetUUIDField = NSTextField(labelWithString: "Asset UUID")
        horizontallyFlippedCheckbox = NSButton(checkboxWithTitle: "Horizontally Flipped", target: nil, action: #selector(Self.onHorizontallyFlippedToggled))
        interactiveCheckbox = NSButton(checkboxWithTitle: "Interactive", target: nil, action: #selector(Self.onInteractiveToggled))
        
        super.init(stackedViews: [
            InspectorHeader(title: "Asset Database"),
            databaseField,
            InspectorHeader(title: "Asset Name / UUID"),
            assetNameField,
            assetUUIDField,
            VSpacer(),
            horizontallyFlippedCheckbox,
            interactiveCheckbox
        ])
        
        horizontallyFlippedCheckbox.target = self
        interactiveCheckbox.target = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateContent() {
        super.updateContent()
        
        if let placement = observableObject as? AssetPlacement {
            let locator = placement.assetLocator
            
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
            
            horizontallyFlippedCheckbox.state = placement.horizontallyFlipped ? .on : .off
            interactiveCheckbox.state = placement.interactive ? .on : .off
        }
    }
    
    @objc
    private func onHorizontallyFlippedToggled() {
        if let placement = observableObject as? AssetPlacement {
            isEditing = true
            placement.horizontallyFlipped = horizontallyFlippedCheckbox.state == .on
            isEditing = false
        }
    }
    
    @objc
    private func onInteractiveToggled() {
        if let placement = observableObject as? AssetPlacement {
            isEditing = true
            placement.interactive = interactiveCheckbox.state == .on
            isEditing = false
        }
    }
    
}
