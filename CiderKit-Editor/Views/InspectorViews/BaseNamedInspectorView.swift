import AppKit
import Combine
import CiderKit_Engine

class BaseNamedInspectorView<InspectedType : ObservableObject & NamedObject> : BaseTypedInspectorView<InspectedType>, NSTextFieldDelegate {

    private let objectNameField: NSTextField

    override init(stackedViews: [NSView]) {
        objectNameField = NSTextField(string: "")

        var views: [NSView] = [
            InspectorHeader(title: "Instance Name"),
            objectNameField
        ]
        if (!stackedViews.isEmpty) {
            views.append(VSpacer())
            views.append(contentsOf: stackedViews)
        }

        super.init(stackedViews: views)

        objectNameField.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateContent() {
        super.updateContent()

        if let inspectedObject {
            objectNameField.stringValue = inspectedObject.name
        }
    }

    func controlTextDidChange(_ obj: Notification) {
        if var inspectedObject {
            isEditing = true
            inspectedObject.name = objectNameField.stringValue
            isEditing = false
        }
    }

}
