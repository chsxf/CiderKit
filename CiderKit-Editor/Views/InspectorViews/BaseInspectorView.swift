import AppKit
import Combine

class BaseInspectorView: NSView {
    
    private(set) var observableObject: AnyObject? = nil {
        didSet {
            if observableObject == nil {
                observableObjectChanged?.cancel()
                observableObjectChanged = nil
            }
            updateContent()
        }
    }
    private var observableObjectChanged: AnyCancellable? = nil

    var isEditing = false
    
    init(stackedViews: [NSView]) {
        super.init(frame: NSZeroRect)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        let stack = NSStackView(views: stackedViews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .left
        stack.spacing = 4
        addSubview(stack)
        
        addConstraints([
            NSLayoutConstraint(item: stack, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: stack, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: stack, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final func setObservableObject<T>(_ observable: T?) where T: ObservableObject {
        guard observableObject !== observable else { return }
        
        observableObject = observable
        if let observable = observable {
            observableObjectChanged = observable.objectWillChange.sink { _ in
                if !self.isEditing {
                    self.updateContent()
                }
            }
        }
    }
    
    func dispose() {
        observableObject = nil
    }
    
    func updateContent() { }
    
}
