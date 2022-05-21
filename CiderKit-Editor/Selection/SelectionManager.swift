import Foundation
import AppKit
import SpriteKit
import GameplayKit
import CiderKit_Engine

class SelectionManager: NSResponder {
    
    private let editorGameView: EditorGameView
        
    private var selectionModel: SelectionModel { editorGameView.selectionModel }
    
    init(editorGameView: EditorGameView) {
        self.editorGameView = editorGameView
        
        super.init()
        
        EditorMapCellComponent.initSelectionShapes(in: editorGameView.scene!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        if let hoverableAndSelectable = selectionModel.hoverable as? Selectable {
            selectionModel.setSelectable(hoverableAndSelectable)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)

        let sceneCoordinates = editorGameView.convert(event.locationInWindow, to: editorGameView.scene!)
        
        var foundHoverable: Hoverable? = nil
        for hoverable in editorGameView.hoverableEntities {
            if hoverable.contains(sceneCoordinates: sceneCoordinates) {
                foundHoverable = hoverable
            }
        }
        selectionModel.setHoverable(foundHoverable)
    }
    
    override func rightMouseUp(with event: NSEvent) {
        super.rightMouseUp(with: event)
        selectionModel.setSelectable(nil)
    }
    
}
