import AppKit

class EditorMainView: NSStackView {
    
    init(gameView: EditorGameView, frame: NSRect) {
        super.init(frame: frame)
        
        orientation = .horizontal
        spacing = 0
        
        addArrangedSubview(gameView)
        
        let inspectorView = InspectorView(selectionModel: gameView.selectionModel, frame: frame)
        addArrangedSubview(inspectorView)
        
        addConstraint(NSLayoutConstraint(item: inspectorView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
