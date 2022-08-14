import AppKit
import Combine
import CiderKit_Engine

class InspectorView: NSView {
    
    private var selectionModel: SelectionModel
    private var onSelectionModelChange: AnyCancellable? = nil

    private var containerView: NSView
    
    init(selectionModel: SelectionModel, frame: NSRect) {
        self.selectionModel = selectionModel
        
        containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: frame)
        
        onSelectionModelChange = selectionModel.objectWillChange.sink { _ in
            DispatchQueue.main.async {
                self.updateContent()
            }
        }
        
        addSubview(containerView)
        
        addConstraints([
            NSLayoutConstraint(item: containerView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 10),
            NSLayoutConstraint(item: containerView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -10),
            NSLayoutConstraint(item: containerView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 10),
            NSLayoutConstraint(item: containerView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -10)
        ])
        
        updateContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateContent() {
        removeControls()
        
        if let selectable = selectionModel.selectable {
            insertInspector(selectable: selectable)
        }
        else {
            insertNoSelectionLabel()
        }
    }
    
    private func removeControls() {
        while !containerView.subviews.isEmpty {
            containerView.subviews.first?.removeFromSuperview()
        }
        
        containerView.removeConstraints(containerView.constraints)
    }
    
    private func insertNoSelectionLabel() {
        let noSelectionLabel = NSTextField(labelWithString: "No selection")
        noSelectionLabel.translatesAutoresizingMaskIntoConstraints = false
        noSelectionLabel.textColor = .gray
        containerView.addSubview(noSelectionLabel)
        
        addConstraints([
            NSLayoutConstraint(item: noSelectionLabel, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: noSelectionLabel, attribute: .centerY, relatedBy: .equal, toItem: containerView, attribute: .centerY, multiplier: 1, constant: 0)
        ])
    }
    
    private func insertInspector(selectable: Selectable) {
        let typeLabel = NSTextField(labelWithString: selectable.inspectableDescription)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.font = NSFont.boldSystemFont(ofSize: 0)
        containerView.addSubview(typeLabel)
        
        addConstraint(NSLayoutConstraint(item: typeLabel, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 0))
        
        if let inspectorView = selectable.inspectorView {
            containerView.addSubview(inspectorView)
            
            addConstraints([
                NSLayoutConstraint(item: inspectorView, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .left, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: inspectorView, attribute: .right, relatedBy: .equal, toItem: containerView, attribute: .right, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: inspectorView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: inspectorView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 48)
            ])
        }
    }
}
