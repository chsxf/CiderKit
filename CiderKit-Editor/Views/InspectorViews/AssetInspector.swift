import CiderKit_Engine
import AppKit

class AssetInspector: BaseNamedInspectorView<AssetPlacement> {

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
        
        if let inspectedObject {
            let locator = inspectedObject.assetLocator

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
            
            horizontallyFlippedCheckbox.state = inspectedObject.horizontallyFlipped ? .on : .off
            interactiveCheckbox.state = inspectedObject.interactive ? .on : .off
        }
    }
    
    @objc
    private func onHorizontallyFlippedToggled() {
        if let inspectedObject {
            isEditing = true
            inspectedObject.horizontallyFlipped = horizontallyFlippedCheckbox.state == .on
            isEditing = false
        }
    }
    
    @objc
    private func onInteractiveToggled() {
        if let inspectedObject {
            isEditing = true
            inspectedObject.interactive = interactiveCheckbox.state == .on
            isEditing = false
        }
    }
    
}
