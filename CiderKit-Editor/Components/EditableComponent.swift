import GameplayKit

enum EditableComponentStatus {
    case valid
    case invalidated
    case deleted
}

class EditableComponent: GKComponent, ObservableObject {
    
    @Published private(set) var status: EditableComponentStatus = .valid
    
    private let delegate: EditableComponentDelegate
    
    init(delegate: EditableComponentDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if status == .invalidated && delegate.validate() {
            status = .valid
        }
    }
    
    func invalidate() {
        status = .invalidated
    }
    
}
