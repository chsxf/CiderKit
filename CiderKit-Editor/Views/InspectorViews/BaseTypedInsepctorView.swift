import AppKit
import CiderKit_Engine

class BaseTypedInspectorView<InspectedType: UpdatableObject> : BaseInspectorView {

    var inspectedObject: InspectedType? { updatableObject as? InspectedType }

    override init(stackedViews: [NSView]) {
        super.init(stackedViews: stackedViews)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
