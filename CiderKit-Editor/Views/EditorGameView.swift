import CoreFoundation
import SpriteKit
import GameplayKit
import SwiftUI

final class EditorGameViewRepresentable: NSViewRepresentable {
    
    static var gameView: EditorGameView? = nil
    
    func makeNSView(context: Context) -> EditorGameView {
        return Self.gameView!
    }

    func updateNSView(_ nsView: EditorGameView, context: Context) {
        
    }
    
}

class EditorGameView: GameView {
    
    private(set) var worldGrid: WorldGrid!
    
    let selectionModel: SelectionModel = SelectionModel()
    
    private var selectionManager: SelectionManager?
    private var viewFrustrumShape: SKShapeNode?
    
    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
        worldGrid = WorldGrid()
        scene!.addChild(worldGrid)
    
        updateViewFrustrum()
        
        DispatchQueue.main.async {
            self.selectionManager = SelectionManager(editorGameView: self)
            self.nextResponder = self.selectionManager
            
            NotificationCenter.default.addObserver(forName: ProjectManager.projectOpened, object: nil, queue: OperationQueue.main) { notif in
                self.updateViewFrustrum()
                self.viewDidEndLiveResize()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateViewFrustrum() {
        if let camera = scene?.camera {
            viewFrustrumShape?.removeFromParent()
            
            let defaultViewWidth = Project.current?.settings.targetResolutionWidth ?? 640
            let defaultViewHeight = Project.current?.settings.targetResolutionHeight ?? 360
            
            viewFrustrumShape = SKShapeNode(rectOf: CGSize(width: defaultViewWidth, height: defaultViewHeight))
            viewFrustrumShape!.strokeColor = .red
            camera.addChild(viewFrustrumShape!)
        }
    }
    
    override func update(_ currentTime: TimeInterval, for scene: SKScene) {
        super.update(currentTime, for: scene)
        
        updateWorldGrid(for: scene)
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
    
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        
        if scene != nil {
            updateWorldGrid(for: scene!)
        }
    }
    
    func updateWorldGrid(for scene: SKScene) {
        guard
            let cam = scene.camera,
            worldGrid != nil
        else {
            return
        }
        
        let viewportRect = CGRect(x: cam.position.x - (scene.size.width / 2), y: cam.position.y - (scene.size.height / 2), width: scene.size.width, height: scene.size.height)
        worldGrid.update(withViewport: viewportRect)
    }
    
    func increaseElevation(area: MapArea?) {
        map.increaseElevation(area: area)
        
        if area != nil {
            selectionModel.setSelectedCell(map.getMapCellEntity(atX: area!.x, y: area!.y))
        }
    }
    
    func decreaseElevation(area: MapArea?) {
        map.decreaseElevation(area: area)
        
        if area != nil {
            selectionModel.setSelectedCell(map.getMapCellEntity(atX: area!.x, y: area!.y))
        }
    }
    
    override func unloadMap(removePreviousMap: Bool = true) {
        super.unloadMap(removePreviousMap: removePreviousMap)
        selectionModel.clear()
    }
    
    override func loadMap(file: URL) {
        super.loadMap(file: file)
        selectionModel.clear()
    }
    
}
