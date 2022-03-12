//
//  GameView.swift
//  SKTestIsoMap
//
//  Created by Christophe SAUVEUR on 17/07/2021.
//

import SpriteKit
import GameplayKit

class GameView: SKView, SKSceneDelegate {

    private var gameScene: SKScene!
    
    private var worldGrid: WorldGrid!
    
    private var map: MapNode!
    
    private var character: GKEntity!
    private var characterComponent: CharacterComponent!
    
    private var hoveringShape: SKShapeNode!
    private var selectionShape: SKShapeNode!
    private var gridHoveringNode: SKNode!
    private var gridHoveredCellEntity: GKEntity!
    private var gridSelectionNode: SKNode!
    private var gridSelectedCellEntity: GKEntity!
    
    let selectionModel: SelectionModel = SelectionModel()
    
    private var debugNode: SKLabelNode!
    
    private var lastTime: TimeInterval?
    
    private var lastMiddleMousePosition: NSPoint = NSPoint()
    
    private var pressedArrows: [Keycode:Bool] = [
        .leftArrow: false,
        .rightArrow: false,
        .upArrow: false,
        .downArrow: false
    ]
    
    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)

        showsFPS = true
        showsDrawCount = true
        showsNodeCount = true
        ignoresSiblingOrder = true
        allowsTransparency = true
        
        let mapDescription: MapDescription = Functions.load("map.json")
        
        try? Atlases.preload(atlases: [
            "main": "Main Atlas",
            "grid": "Grid Atlas"
        ]) {
            let scene = SKScene(size: frameRect.size)
            self.gameScene = scene
            scene.delegate = self
            
            let cam = SKCameraNode()
            scene.camera = cam
            scene.addChild(cam)
            
            self.presentScene(scene)
          
            self.worldGrid = WorldGrid()
            scene.addChild(self.worldGrid)
            
            self.map = MapNode(description: mapDescription)
            scene.addChild(self.map)
            
            self.initSelectionShapes()
            //self.initCharacter()
            self.initDebug()
        }
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
        gameScene.addChild(selectionShape)
        
        hoveringShape = SKShapeNode(points: &points, count: points.count)
        hoveringShape.strokeShader = SKShader(fileNamed: "HoverShader")
        hoveringShape.strokeColor = NSColor.red
        hoveringShape.lineWidth = 1
        hoveringShape.zPosition = 1000001
        hoveringShape.isHidden = true
        gameScene.addChild(hoveringShape)
        
        gridSelectionNode = SKNode()
        gameScene.addChild(gridSelectionNode)
        
        gridSelectedCellEntity = GKEntity()
        gridSelectedCellEntity.addComponent(GKSKNodeComponent(node: gridSelectionNode))
        gridSelectedCellEntity.addComponent(MapCellComponent(mapX: 0, mapY: 0))
        
        gridHoveringNode = SKNode()
        gameScene.addChild(gridHoveringNode)
        
        gridHoveredCellEntity = GKEntity()
        gridHoveredCellEntity.addComponent(GKSKNodeComponent(node: gridHoveringNode))
        gridHoveredCellEntity.addComponent(MapCellComponent(mapX: 0, mapY: 0))
    }
    
//    func initCharacter() {
//        let texture = Atlases.main["test_character"]
//        let sprite = SKSpriteNode(texture: texture)
//        sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
//        sprite.zPosition = 10000
//        scene!.addChild(sprite)
//
//        character = GKEntity()
//        character.addComponent(GKSKNodeComponent(node: sprite))
//
//        let minimapMarker = gameScene.childNode(withName: "//MinimapMarker")!
//
//        characterComponent = CharacterComponent(startPositionX: 1, y: 4, onMap: gameScene.map, miniMapNode: minimapMarker)
//        character.addComponent(characterComponent)
//    }

    func initDebug() {
        debugNode = SKLabelNode()
        debugNode.position = CGPoint(x: -300, y: 150)
        debugNode.zPosition = 10000
        debugNode.numberOfLines = 0

        debugNode.fontSize = 10
        debugNode.verticalAlignmentMode = .top
        debugNode.horizontalAlignmentMode = .left

        gameScene.camera!.addChild(debugNode)
    }
    
    func update(_ currentTime: TimeInterval, for scene: SKScene) {
        guard
            let cam = scene.camera,
            worldGrid != nil
        else {
            return
        }
        
        let viewportRect = CGRect(x: cam.position.x - (scene.size.width / 2), y: cam.position.y - (scene.size.height / 2), width: scene.size.width, height: scene.size.height)
        worldGrid.update(withViewport: viewportRect)
        
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
        
//        guard let lastTime = lastTime else {
//            lastTime = currentTime
//            return
//        }
//
//        var x: CGFloat = 0
//        if pressedArrows[.leftArrow]! {
//            x -= 1
//        }
//        if pressedArrows[.rightArrow]! {
//            x += 1
//        }
//
//        var y: CGFloat = 0
//        if pressedArrows[.upArrow]! {
//            y += 1
//        }
//        if pressedArrows[.downArrow]! {
//            y -= 1
//        }
//
//        characterComponent.direction = CGPoint(x: x, y: y)
//
//        let timeDiff = currentTime - lastTime
//        self.lastTime = currentTime
//        character.update(deltaTime: timeDiff)
//
//        var debugMessage = String(format: "Map position: %.3f : %.3f\n", characterComponent.mapPosition.x, characterComponent.mapPosition.y)
//        + String(format: "Integral part: %d : %d\n", characterComponent.integralX, characterComponent.integralY)
//        + String(format: "Fractional part: %.3f : %.3f\n", characterComponent.fractionalX, characterComponent.fractionalY)
//
//        var transformedMapVector = CGPoint(x: characterComponent.fractionalX, y: characterComponent.fractionalY)
//        transformedMapVector = transformedMapVector.applying(CGAffineTransform(rotationAngle: .pi * -45.0 / 180.0))
//        transformedMapVector = transformedMapVector.applying(CGAffineTransform(scaleX: sqrt(2), y: sqrt(2)))
//        debugMessage += String(format: "Transformed (unit): %.3f : %.3f\n", transformedMapVector.x, transformedMapVector.y)
//        transformedMapVector = transformedMapVector.applying(CGAffineTransform(scaleX: CGFloat(MapNode.halfWidth), y: CGFloat(MapNode.halfHeight)))
//        debugMessage += String(format: "Transformed (pixels): %.3f : %.3f\n", transformedMapVector.x, transformedMapVector.y)
//
//        debugNode.text = debugMessage
    }
    
    override func keyDown(with event: NSEvent) {
        guard
            !event.isARepeat,
            let keycode = Keycode(rawValue: event.keyCode)
        else {
            return
        }
        
        switch keycode {
        case .leftArrow, .rightArrow, .downArrow, .upArrow:
            pressedArrows[keycode] = true
            break
        default:
            break
        }
    }
    
    override func keyUp(with event: NSEvent) {
        guard let keycode = Keycode(rawValue: event.keyCode) else {
            return
        }
        
        switch keycode {
        case .leftArrow, .rightArrow, .downArrow, .upArrow:
            pressedArrows[keycode] = false
            break
        default:
            break
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if selectionModel.hoveredCell == gridHoveredCellEntity {
            let hoveredNode = gridHoveredCellEntity.component(ofType: GKSKNodeComponent.self)!.node
            let hoveredCellComponent = gridHoveredCellEntity.component(ofType: MapCellComponent.self)!
            
            let node = gridSelectedCellEntity.component(ofType: GKSKNodeComponent.self)!.node
            node.position = hoveredNode.position
            let cellComponent = gridSelectedCellEntity.component(ofType: MapCellComponent.self)!
            cellComponent.mapX = hoveredCellComponent.mapX
            cellComponent.mapY = hoveredCellComponent.mapY
            selectionModel.selectedCell = gridSelectedCellEntity
        }
        else {
            selectionModel.selectedCell = selectionModel.hoveredCell
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        var str = String(format: "Mouse position (window): %.0f : %.0f", window!.mouseLocationOutsideOfEventStream.x, window!.mouseLocationOutsideOfEventStream.y)
        let sceneCoordinates = convert(window!.mouseLocationOutsideOfEventStream, to: scene!)
        str += String(format: "\nMouse position (scene): %.0f : %.0f", sceneCoordinates.x, sceneCoordinates.y)
        
        selectionModel.hoveredCell = nil
        for region in map.regions {
            if region.calculateAccumulatedFrame().contains(sceneCoordinates) {
                for cell in region.cellEntities {
                    if cell.component(ofType: MapCellComponent.self)!.containsScenePosition(sceneCoordinates) {
                        selectionModel.hoveredCell = cell
                    }
                }
            }
        }
        str += "\nHovering cell: \(selectionModel.hoveredCell != nil)"
        
        if selectionModel.hoveredCell == nil {
            let worldPosition = Math.sceneToWorld(sceneCoordinates, halfTileSize: worldGrid.halfGridTileSize)
            let gridCellPosition = CGPoint(x: worldPosition.x.rounded(.down), y: worldPosition.y.rounded(.down))
            str += String(format: "\n\nGrid cell position: %.0f : %.0f", gridCellPosition.x, gridCellPosition.y)
            
            let node = gridHoveredCellEntity.component(ofType: GKSKNodeComponent.self)!.node
            node.position = Math.worldToScene(gridCellPosition, halfTileSize: worldGrid.halfGridTileSize)
            let cellComponent = gridHoveredCellEntity.component(ofType: MapCellComponent.self)!
            cellComponent.mapX = Int(gridCellPosition.x)
            cellComponent.mapY = Int(gridCellPosition.y)
            selectionModel.hoveredCell = gridHoveredCellEntity
        }
        
        debugNode.text = str
    }
    
    override func otherMouseDown(with event: NSEvent) {
        guard
            let window = self.window,
            event.buttonNumber == 2
        else {
            return
        }
        lastMiddleMousePosition = window.mouseLocationOutsideOfEventStream
        NSCursor.closedHand.push()
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        guard
            let window = self.window,
            let contentView = window.contentView,
            let scene = scene,
            let camera = scene.camera,
            event.buttonNumber == 2
        else {
            return
        }
        
        let mousePosition = window.mouseLocationOutsideOfEventStream
        let diff = mousePosition.applying(CGAffineTransform(translationX: lastMiddleMousePosition.x, y: lastMiddleMousePosition.y).inverted())

        let contentViewSize = contentView.visibleRect.size
        let sceneSize = scene.size
        let viewToSceneMultipliers = CGPoint(
            x: sceneSize.width / contentViewSize.width,
            y: sceneSize.height / contentViewSize.height
        )
        
        let worldDiff = diff.applying(CGAffineTransform.init(scaleX: viewToSceneMultipliers.x, y: viewToSceneMultipliers.y))
        camera.position = camera.position.applying(CGAffineTransform(translationX: worldDiff.x, y: worldDiff.y).inverted())
        
        lastMiddleMousePosition = mousePosition
    }
    
    override func otherMouseUp(with event: NSEvent) {
        if event.buttonNumber == 2 {
            NSCursor.pop()
        }
    }
    
    override func rightMouseUp(with event: NSEvent) {
        selectionModel.selectedCell = nil
    }
    
}
