import Foundation
import AppKit
import SpriteKit
import GameplayKit

class SelectionManager: NSResponder {
    
    private let editorGameView: EditorGameView
    
    private var hoveringShape: SKShapeNode!
    private var selectionShape: SKShapeNode!
    private var gridHoveringNode: SKNode!
    private var gridHoveredCellEntity: GKEntity!
    private var gridSelectionNode: SKNode!
    private var gridSelectedCellEntity: GKEntity!
    
    private var selectionModel: SelectionModel { editorGameView.selectionModel }
    
    init(editorGameView: EditorGameView) {
        self.editorGameView = editorGameView
        
        super.init()
        
        initSelectionShapes()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initSelectionShapes() {
        var points: [CGPoint] = [
            CGPoint(x: -24, y: -12),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 24, y: -12),
            CGPoint(x: 0, y: -24),
            CGPoint(x: -24, y: -12)
        ]
        
        selectionShape = SKShapeNode(points: &points, count: points.count)
        selectionShape.strokeColor = NSColor.yellow
        selectionShape.lineWidth = 1
        selectionShape.zPosition = 1000000
        selectionShape.isHidden = true
        editorGameView.scene?.addChild(selectionShape)
        
        hoveringShape = SKShapeNode(points: &points, count: points.count)
        hoveringShape.strokeShader = SKShader(fileNamed: "HoverShader")
        hoveringShape.strokeColor = NSColor.red
        hoveringShape.lineWidth = 1
        hoveringShape.zPosition = 1000001
        hoveringShape.isHidden = true
        editorGameView.scene?.addChild(hoveringShape)
        
        gridSelectionNode = SKNode()
        editorGameView.scene?.addChild(gridSelectionNode)
        
        gridSelectedCellEntity = GKEntity()
        gridSelectedCellEntity.addComponent(GKSKNodeComponent(node: gridSelectionNode))
        gridSelectedCellEntity.addComponent(MapCellComponent(mapX: 0, mapY: 0))
        
        gridHoveringNode = SKNode()
        editorGameView.scene?.addChild(gridHoveringNode)
        
        gridHoveredCellEntity = GKEntity()
        gridHoveredCellEntity.addComponent(GKSKNodeComponent(node: gridHoveringNode))
        gridHoveredCellEntity.addComponent(MapCellComponent(mapX: 0, mapY: 0))
    }
    
    func update() {
        if selectionModel.hoveredCell != nil {
            let node = selectionModel.hoveredCell!.component(ofType: GKSKNodeComponent.self)!.node
            hoveringShape.position = node.position
            hoveringShape.isHidden = false
        }
        else {
            hoveringShape.isHidden = true
        }
        
        if selectionModel.selectedCell != nil {
            let node = selectionModel.selectedCell!.component(ofType: GKSKNodeComponent.self)!.node
            selectionShape.position = node.position
            selectionShape.isHidden = false
        }
        else {
            selectionShape.isHidden = true
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        if selectionModel.hoveredCell == gridHoveredCellEntity {
            let hoveredNode = gridHoveredCellEntity.component(ofType: GKSKNodeComponent.self)!.node
            let hoveredCellComponent = gridHoveredCellEntity.component(ofType: MapCellComponent.self)!
            
            let node = gridSelectedCellEntity.component(ofType: GKSKNodeComponent.self)!.node
            node.position = hoveredNode.position
            let cellComponent = gridSelectedCellEntity.component(ofType: MapCellComponent.self)!
            cellComponent.mapX = hoveredCellComponent.mapX
            cellComponent.mapY = hoveredCellComponent.mapY
            selectionModel.setSelectedCell(gridSelectedCellEntity)
        }
        else {
            selectionModel.setSelectedCell(selectionModel.hoveredCell)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        let sceneCoordinates = editorGameView.convert(event.locationInWindow, to: editorGameView.scene!)
        
        selectionModel.setHoveredCell(nil)
        for region in editorGameView.map {
            if region.calculateAccumulatedFrame().contains(sceneCoordinates) {
                for cell in region.cellEntities {
                    if cell.component(ofType: MapCellComponent.self)!.containsScenePosition(sceneCoordinates) {
                        selectionModel.setHoveredCell(cell)
                    }
                }
            }
        }
        
        if selectionModel.hoveredCell == nil {
            let worldGrid: WorldGrid = editorGameView.worldGrid
            
            let worldPosition = Math.sceneToWorld(sceneCoordinates, halfTileSize: worldGrid.halfGridTileSize)
            let gridCellPosition = CGPoint(x: worldPosition.x.rounded(.down), y: worldPosition.y.rounded(.down))
            
            let node = gridHoveredCellEntity.component(ofType: GKSKNodeComponent.self)!.node
            node.position = Math.worldToScene(gridCellPosition, halfTileSize: worldGrid.halfGridTileSize)
            let cellComponent = gridHoveredCellEntity.component(ofType: MapCellComponent.self)!
            cellComponent.mapX = Int(gridCellPosition.x)
            cellComponent.mapY = Int(gridCellPosition.y)
            selectionModel.setHoveredCell(gridHoveredCellEntity)
        }
    }
    
    override func rightMouseUp(with event: NSEvent) {
        super.rightMouseUp(with: event)
        selectionModel.setSelectedCell(nil)
    }
    
}
