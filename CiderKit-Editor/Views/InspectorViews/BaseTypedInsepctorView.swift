import AppKit
import Combine

class BaseTypedInspectorView<InspectedType : ObservableObject> : BaseInspectorView {

    var inspectedObject: InspectedType? { observableObject as? InspectedType }

    override init(stackedViews: [NSView]) {
        super.init(stackedViews: stackedViews)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
