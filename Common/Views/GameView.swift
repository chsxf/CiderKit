//
//  GameView.swift
//  SKTestIsoMap
//
//  Created by Christophe SAUVEUR on 17/07/2021.
//

import SpriteKit
import GameplayKit

public class GameView: SKView, SKSceneDelegate {

    internal var gameScene: SKScene!
    
    private(set) var map: MapNode!
    
    private var character: GKEntity!
    private var characterComponent: CharacterComponent!
    
    internal var debugNode: SKLabelNode!
    
    private var lastTime: TimeInterval?
    
    private var pressedArrows: [Keycode:Bool] = [
        .leftArrow: false,
        .rightArrow: false,
        .upArrow: false,
        .downArrow: false
    ]
    
    override public init(frame frameRect: CGRect) {
        super.init(frame: frameRect)

        showsFPS = true
        showsDrawCount = true
        showsNodeCount = true
        ignoresSiblingOrder = true
        allowsTransparency = true
        
        let scene = SKScene(size: frameRect.size)
        self.gameScene = scene
        scene.delegate = self
        
        let cam = SKCameraNode()
        gameScene.camera = cam
        gameScene.addChild(cam)
        
        presentScene(gameScene)
        
        unloadMap(removePreviousMap: false)
      
        //self.initCharacter()
        initDebug()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    public func update(_ currentTime: TimeInterval, for scene: SKScene) {
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
    
    override public func keyDown(with event: NSEvent) {
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
    
    override public func keyUp(with event: NSEvent) {
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
    
    public func loadMap(file: URL) {
        unloadMap()
        
        let mapDescription: MapDescription = Functions.load(file)
        map = MapNode(description: mapDescription)
        gameScene.addChild(map!)
    }
    
    public func unloadMap(removePreviousMap: Bool = true) {
        if removePreviousMap {
            map.removeFromParent()
        }
        
        let mapDescription = MapDescription()
        map = MapNode(description: mapDescription)
        gameScene.addChild(map)
    }
    
}
