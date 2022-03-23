//
//  EditorGameView.swift
//  CiderKit-Editor
//
//  Created by Christophe on 20/03/2022.
//

import CoreFoundation
import SpriteKit
import GameplayKit

class EditorGameView: GameView {
    
    private(set) var worldGrid: WorldGrid!
    
    let selectionModel: SelectionModel = SelectionModel()
    
    private var selectionManager: SelectionManager?
    
    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didCompleteInitialization() {
        super.didCompleteInitialization()
        
        worldGrid = WorldGrid()
        scene!.addChild(worldGrid)
    
        DispatchQueue.main.async {
            self.selectionManager = SelectionManager(editorGameView: self)
            self.nextResponder = self.selectionManager
        }
    }
    
    override func update(_ currentTime: TimeInterval, for scene: SKScene) {
        super.update(currentTime, for: scene)
        
        guard
            let cam = scene.camera,
            worldGrid != nil
        else {
            return
        }
        
        let viewportRect = CGRect(x: cam.position.x - (scene.size.width / 2), y: cam.position.y - (scene.size.height / 2), width: scene.size.width, height: scene.size.height)
        worldGrid.update(withViewport: viewportRect)
        
        selectionManager?.update()
    }
    
    override func mouseDown(with event: NSEvent) {
        nextResponder?.mouseDown(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        nextResponder?.mouseUp(with: event)
    }
    
    override func mouseMoved(with event: NSEvent) {
        nextResponder?.mouseMoved(with: event)
    }
    
    override func rightMouseUp(with event: NSEvent) {
        nextResponder?.rightMouseUp(with: event)
    }
    
    override func otherMouseDown(with event: NSEvent) {
        guard event.buttonNumber == 2 else {
            return
        }
        NSCursor.closedHand.push()
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        guard
            let scene = scene,
            let camera = scene.camera,
            event.buttonNumber == 2
        else {
            return
        }
        
        let diff = CGPoint(x: event.deltaX, y: -event.deltaY)

        let contentViewSize = visibleRect.size
        let sceneSize = scene.size
        let viewToSceneMultipliers = CGPoint(
            x: sceneSize.width / contentViewSize.width,
            y: sceneSize.height / contentViewSize.height
        )
        
        let worldDiff = diff.applying(CGAffineTransform.init(scaleX: viewToSceneMultipliers.x, y: viewToSceneMultipliers.y))
        camera.position = camera.position.applying(CGAffineTransform(translationX: worldDiff.x, y: worldDiff.y).inverted())
    }
    
    override func otherMouseUp(with event: NSEvent) {
        if event.buttonNumber == 2 {
            NSCursor.pop()
        }
    }
    
}
