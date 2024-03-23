import Foundation
import AppKit
import SpriteKit
import GameplayKit
import CiderKit_Engine
import Combine

fileprivate struct OutlineData {
    
    var selected: Bool = false
    var hovered: Bool = false
    var frame: CGRect
    var node: SKShapeNode? = nil
    
}

class SelectionManager: NSResponder {
    
    private let editorGameView: EditorGameView
    
    private let selectionOutlinesRoot: SKNode
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
    
    private var outlines = [UUID: OutlineData]()
    
    init(editorGameView: EditorGameView) {
        self.editorGameView = editorGameView
        
        selectionOutlinesRoot = SKNode()
        selectionOutlinesRoot.zPosition = 11000
        
        toolsRoot = SKNode()
        toolsRoot.zPosition = selectionOutlinesRoot.zPosition + 1
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SelectionManager.onSelectableUpdated(notification:)), name: .selectableUpdated, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onSelectableHighlighted(notification:)), name: .selectableHighlighted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onSelectableDeemphasized(notification:)), name: .selectableDeemphasized, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onHoverableHovered(notification:)), name: .hoverableHovered, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onSelectableDeparted(notification:)), name: .hoverableDeparted, object: nil)
        
        let scene = editorGameView.scene!
        scene.addChild(selectionOutlinesRoot)
        EditorMapCellComponent.initSelectionShapes(in: selectionOutlinesRoot)
        scene.addChild(toolsRoot)
        initTools()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideTools() {
        toolsRoot.isHidden = true
    }
    
    func showTools() {
        toolsRoot.isHidden = false
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
    
    func deleteCurrentSelectable() {
        guard let currentSelectable = selectionModel.selectable else { return }
        
        if currentSelectable.supportedToolModes.contains(.erase) {
            if selectionModel.hoverable === currentSelectable {
                selectionModel.setHoverable(nil)
            }
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
    
    @objc
    private func onSelectableHighlighted(notification: Notification) {
        guard let assetInstance = notification.object as? AssetInstance, let assetNode = assetInstance.node else { return }
        requestSelectionOutline(for: assetInstance.uuid, with: assetNode.calculateAccumulatedFrame())
    }
    
    func requestSelectionOutline(for uuid: UUID, with frame: CGRect) {
        var outlineData = outlines[uuid]
        
        if outlineData == nil {
            outlineData = OutlineData(selected: true, frame: frame, node: createOutline(with: frame))
        }
        else {
            outlineData!.selected = true
            if frame != outlineData!.frame {
                outlineData!.frame = frame
                outlineData!.node = createOutline(with: frame)
            }
        }
        
        outlines[uuid] = outlineData!
        updateOutlineColor(outlineData: outlineData)
    }
    
    @objc
    private func onSelectableDeemphasized(notification: Notification) {
        guard let assetInstance = notification.object as? AssetInstance else { return }
        dismissSelectionOutline(for: assetInstance.uuid)
    }
    
    func dismissSelectionOutline(for uuid: UUID) {
        guard var outlineData = outlines[uuid] else { return }
        
        outlineData.selected = false
        if !outlineData.hovered {
            outlineData.node?.removeFromParent()
            outlines[uuid] = nil
        }
        else {
            outlines[uuid] = outlineData
            updateOutlineColor(outlineData: outlineData)
        }
    }
    
    func dismissAllSelectionOutlines() {
        for (uuid, _) in outlines {
            dismissHoverOutline(for: uuid)
        }
    }
    
    @objc
    private func onHoverableHovered(notification: Notification) {
        guard let assetInstance = notification.object as? AssetInstance, let assetNode = assetInstance.node else { return }
        requestHoverOutline(for: assetInstance.uuid, with: assetNode.calculateAccumulatedFrame())
    }
    
    func requestHoverOutline(for uuid: UUID, with frame: CGRect) {
        var outlineData = outlines[uuid]
        
        if outlineData == nil {
            outlineData = OutlineData(hovered: true, frame: frame, node: createOutline(with: frame))
        }
        else {
            outlineData!.hovered = true
            if frame != outlineData!.frame {
                outlineData!.frame = frame
                outlineData!.node = createOutline(with: frame)
            }
        }
        
        outlines[uuid] = outlineData!
        updateOutlineColor(outlineData: outlineData)
    }
    
    @objc
    private func onSelectableDeparted(notification: Notification) {
        guard let assetInstance = notification.object as? AssetInstance else { return }
        dismissHoverOutline(for: assetInstance.uuid)
    }
    
    func dismissHoverOutline(for uuid: UUID) {
        guard var outlineData = outlines[uuid] else { return }
        
        outlineData.hovered = false
        if !outlineData.selected {
            outlineData.node?.removeFromParent()
            outlines[uuid] = nil
        }
        else {
            outlines[uuid] = outlineData
            updateOutlineColor(outlineData: outlineData)
        }
    }
    
    func dismissAllHoverOutlines() {
        for (uuid, _) in outlines {
            dismissHoverOutline(for: uuid)
        }
    }
    
    private func createOutline(with rect: CGRect) -> SKShapeNode {
        let outline = SKShapeNode(rect: rect)
        outline.lineWidth = 1
        selectionOutlinesRoot.addChild(outline)
        return outline
    }
    
    private func updateOutlineColor(outlineData: OutlineData?) {
        guard let outlineData, let node = outlineData.node else { return }
        
        let color = outlineData.selected ? SKColor.green : SKColor.red
        node.strokeColor = color
    }
    
}
