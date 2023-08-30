import Foundation
import AppKit
import SpriteKit
import GameplayKit
import CiderKit_Engine
import Combine

class SelectionManager: NSResponder {
    
    private let editorGameView: EditorGameView
    
    private let toolsRoot: SKNode
    private var toolsByMode: [ToolMode: (GKEntity, Tool)] = [:]
    private var currentActiveTool: Tool? = nil
    private var previousDownSceneCoordinates: CGPoint = CGPoint.zero
    
    private var selectionModel: SelectionModel { editorGameView.selectionModel }
    
    private var editableSubscription: AnyCancellable? = nil
    
    var currentToolMode: ToolMode = .select {
        didSet {
            if currentToolMode != oldValue {
                if let selectable = selectionModel.selectable {
                    updateFor(selectable: selectable)
                }
            }
        }
    }
    
    init(editorGameView: EditorGameView) {
        self.editorGameView = editorGameView
        toolsRoot = SKNode()
        toolsRoot.zPosition = 11000
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SelectionManager.onSelectableUpdated(notification:)), name: .selectableUpdated, object: nil)
        
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
        if let currentActiveTool = currentActiveTool {
            let sceneCoordinates = event.location(in: editorGameView.scene!)
            if currentActiveTool.contains(sceneCoordinates: sceneCoordinates) {
                currentActiveTool.mouseUp(atX: sceneCoordinates.x, y: sceneCoordinates.y)
                return
            }
        }
        
        if let hoverableAndSelectable = selectionModel.hoverable as? Selectable {
            selectionModel.setSelectable(hoverableAndSelectable)
        }
    }
    
    @objc
    private func onSelectableUpdated(notification: Notification) {
        if let selectable = notification.object as? Selectable {
            updateFor(selectable: selectable)
        }
    }
    
    private func updateFor(selectable: Selectable) {
        disableAllTools()
        if selectable.supportedToolModes.contains(currentToolMode) {
            if let tool = toolsByMode[currentToolMode]?.1 {
                tool.moveTo(scenePosition: selectable.scenePosition)
                tool.enabled = true
                currentActiveTool = tool
                currentActiveTool?.linkedSelectable = selectable
            }
        }
        
        editableSubscription?.cancel()
        if let editableComponent = (selectable as? GKComponent)?.entity?.component(ofType: EditableComponent.self) {
            editableSubscription = editableComponent.objectWillChange.sink { self.editorGameView.mutableMap.dirty = true }
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
        deselect();
    }
    
    override func keyUp(with event: NSEvent) {
        guard let currentSelectable = selectionModel.selectable else { return }
        
        if event.specialKey == .delete && currentSelectable.supportedToolModes.contains(.erase) {
            deselect()
            currentSelectable.erase()
        }
    }
    
    func deselect() {
        selectionModel.setSelectable(nil)
        disableAllTools()
        editableSubscription?.cancel()
    }
    
    private func initTools() {
        let moveToolEntity = MoveToolComponent.entity(parentNode: toolsRoot)
        if let tool = moveToolEntity.findTool() {
            toolsByMode[.move] = (moveToolEntity, tool)
            tool.enabled = false
        }
        
        let elevationToolEntity = ElevationToolComponent.entity(parentNode: toolsRoot)
        if let tool = elevationToolEntity.findTool() {
            toolsByMode[.elevation] = (elevationToolEntity, tool)
            tool.enabled = false
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
