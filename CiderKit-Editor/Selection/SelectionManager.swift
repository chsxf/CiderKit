import Foundation
import AppKit
import SpriteKit
import GameplayKit
import CiderKit_Engine

class SelectionManager: NSResponder {
    
    private let editorGameView: EditorGameView
    
    private let toolsRoot: SKNode
    private var toolsByMode: [ToolMode: (GKEntity, Tool)] = [:]
    private var currentToolMode: ToolMode = .move
    private var currentActiveTool: Tool? = nil
    private var previousDownSceneCoordinates: CGPoint = CGPoint.zero
    
    private var selectionModel: SelectionModel { editorGameView.selectionModel }
    
    init(editorGameView: EditorGameView) {
        self.editorGameView = editorGameView
        toolsRoot = SKNode()
        toolsRoot.zPosition = 11000
        
        super.init()
        
        let scene = editorGameView.scene!
        EditorMapCellComponent.initSelectionShapes(in: scene)
        scene.addChild(toolsRoot)
        initTools()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        if let currentActiveTool = currentActiveTool {
            let sceneCoordinates = event.location(in: editorGameView.scene!)
            if currentActiveTool.contains(sceneCoordinates: sceneCoordinates) {
                previousDownSceneCoordinates = sceneCoordinates
            }
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if let hoverableAndSelectable = selectionModel.hoverable as? Selectable {
            selectionModel.setSelectable(hoverableAndSelectable)
            
            if hoverableAndSelectable.supportedToolModes.contains(currentToolMode) {
                if let tool = toolsByMode[currentToolMode]?.1 {
                    tool.moveTo(scenePosition: hoverableAndSelectable.scenePosition)
                    tool.enabled = true
                    currentActiveTool = tool
                    currentActiveTool?.linkedSelectable = hoverableAndSelectable
                }
            }
            else {
                disableAllTools()
            }
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        let sceneCoordinates = event.location(in: editorGameView.scene!)
        
        var overActiveTool = false
        if let currentActiveTool = currentActiveTool {
            if currentActiveTool.contains(sceneCoordinates: sceneCoordinates) {
                currentActiveTool.hovered()
                overActiveTool = true
            }
            else {
                currentActiveTool.departed()
            }
        }
        
        var foundHoverable: Hoverable? = nil
        if !overActiveTool {
            for hoverable in editorGameView.hoverableEntities {
                if hoverable.contains(sceneCoordinates: sceneCoordinates) {
                    foundHoverable = hoverable
                }
            }
        }
        selectionModel.setHoverable(foundHoverable)
    }
    
    override func mouseDragged(with event: NSEvent) {
        if let currentActiveTool = currentActiveTool {
            if currentActiveTool.interactedWith {
                let sceneCoordinates = event.location(in: editorGameView.scene!)
                let diffX = sceneCoordinates.x - previousDownSceneCoordinates.x
                let diffY = sceneCoordinates.y - previousDownSceneCoordinates.y
                previousDownSceneCoordinates = sceneCoordinates
                currentActiveTool.dragInScene(byX: diffX, y: diffY)
            }
        }
    }
    
    override func rightMouseUp(with event: NSEvent) {
        selectionModel.setSelectable(nil)
        disableAllTools()
    }
    
    private func initTools() {
        let moveToolEntity = MoveToolComponent.entity(parentNode: toolsRoot)
        if let moveTool = moveToolEntity.findTool() {
            toolsByMode[.move] = (moveToolEntity, moveTool)
            moveTool.enabled = false
        }
    }
    
    private func disableAllTools() {
        for entry in toolsByMode {
            entry.value.1.enabled = false
        }
        currentActiveTool?.departed()
        currentActiveTool?.linkedSelectable = nil
        currentActiveTool = nil
    }
    
    func update() {
        if
            let currentActiveTool = currentActiveTool,
            let linkedSelectable = currentActiveTool.linkedSelectable
        {
            currentActiveTool.moveTo(scenePosition: linkedSelectable.scenePosition)
        }
    }
    
}
