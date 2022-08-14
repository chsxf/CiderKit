final class InspectorViewFactory {
    
    private static var viewsByClass: [ObjectIdentifier: BaseInspectorView] = [:]
    
    public static func getView(forClass: AnyClass, generator: () -> BaseInspectorView) -> BaseInspectorView {
        let identifier = ObjectIdentifier(forClass)
        
        if let view = viewsByClass[identifier] {
            return view
        }
        
        let newView = generator()
        viewsByClass[identifier] = newView
        return newView
    }
    
}
