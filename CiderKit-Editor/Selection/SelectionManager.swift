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
    private var previousDownSceneCoordinates: ScenePosition = ScenePosition.zero

    private var selectionModel: SelectionModel { editorGameView.selectionModel }
    
    private var editableSubscription: AnyCancellable? = nil
    
    private var notificationTask: Task<Void, Never>? = nil
    
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
        
        let scene = editorGameView.scene!
        scene.addChild(selectionOutlinesRoot)
        EditorMapCellComponent.initSelectionShapes(in: selectionOutlinesRoot)
        scene.addChild(toolsRoot)
        initTools()
        
        notificationTask = setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        notificationTask?.cancel()
    }
    
    func setupNotifications() -> Task<Void, Never> {
        Task {
            await withThrowingTaskGroup { group in
                group.addTask {
                    for await selectable in NotificationCenter.default.notifications(named: .selectableUpdated).compactMap({ $0.object as? Selectable }) {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.onSelectableUpdated(selectable: selectable)
                        }
                    }
                }
                
                group.addTask {
                    for await assetInstance in NotificationCenter.default.notifications(named: .selectableHighlighted).compactMap({ $0.object as? AssetInstance }) {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.onSelectableHighlighted(assetInstance: assetInstance)
                        }
                    }
                }
                
                group.addTask {
                    for await assetInstance in NotificationCenter.default.notifications(named: .selectableDeemphasized).compactMap({ $0.object as? AssetInstance }) {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.onSelectableDeemphasized(assetInstance: assetInstance)
                        }
                    }
                }
                
                group.addTask {
                    for await assetInstance in NotificationCenter.default.notifications(named: .hoverableHovered).compactMap({ $0.object as? AssetInstance }) {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.onHoverableHovered(assetInstance: assetInstance)
                        }
                    }
                }
                
                group.addTask {
                    for await assetInstance in NotificationCenter.default.notifications(named: .hoverableDeparted).compactMap({ $0.object as? AssetInstance }) {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.onSelectableDeparted(assetInstance: assetInstance)
                        }
                    }
                }
            }
        }
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
                currentActiveTool.mouseUp(atSceneX: sceneCoordinates.x, y: sceneCoordinates.y)
                return
            }
        }
        
        if let hoverableAndSelectable = selectionModel.hoverable as? Selectable {
            selectionModel.setSelectable(hoverableAndSelectable)
        }
    }
    
    private func onSelectableUpdated(selectable: Selectable) {
        updateFor(selectable: selectable)
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
            editableSubscription = editableComponent.objectWillChange.sink { self.editorGameView.mutableMap?.dirty = true }
        }
        else if let editorMapCellComponent = (selectable as? EditorMapCellComponent) {
            editableSubscription = editorMapCellComponent.objectWillChange.sink { self.editorGameView.mutableMap?.dirty = true }
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
                currentActiveTool.dragInScene(bySceneX: diffX, y: diffY)
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
    
    private func onSelectableHighlighted(assetInstance: AssetInstance) {
        guard let assetNode = assetInstance.node else { return }
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
    
    private func onSelectableDeemphasized(assetInstance: AssetInstance) {
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
    
    private func onHoverableHovered(assetInstance: AssetInstance) {
        guard let assetNode = assetInstance.node else { return }
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
    
    private func onSelectableDeparted(assetInstance: AssetInstance) {
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
