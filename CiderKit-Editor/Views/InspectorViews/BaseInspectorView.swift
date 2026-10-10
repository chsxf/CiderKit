import AppKit
import CiderKit_Engine

class BaseInspectorView: NSView {
    
    private(set) var updatableObject: any UpdatableObject? = nil

    private var notificationTask: Task<Void, Never>? = nil

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

    deinit {
        notificationTask?.cancel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupNotificationTask() -> Task<Void, Never> {
        Task {
            await withThrowingTaskGroup { group in
                group.addTask {
                    if let updatableObject = await self.updatableObject {
                        for await _ in updatableObject.updated {
                            try Task.checkCancellation()
                            await MainActor.run {
                                self.updateContent()
                            }
                        }
                    }
                }
            }
        }
    }

    final func setUpdatableObject(_ updatable: any UpdatableObject?) {
        guard updatableObject !== updatable else { return }
        
        updatableObject = updatable
        notificationTask?.cancel()
        notificationTask = nil
        if updatableObject != nil {
            notificationTask = setupNotificationTask()
        }
    }
    
    func dispose() {
        updatableObject = nil
        notificationTask?.cancel()
        notificationTask = nil
    }
    
    func updateContent() { }
    
}
