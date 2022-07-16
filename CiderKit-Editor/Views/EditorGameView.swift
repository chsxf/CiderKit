import CoreFoundation
import SpriteKit
import GameplayKit
import SwiftUI
import CiderKit_Engine

struct EditorGameViewRepresentable: NSViewRepresentable {
    
    private var gameView: EditorGameView
    
    init(gameView: EditorGameView) {
        self.gameView = gameView
    }
    
    func makeNSView(context: Context) -> EditorGameView {
        return gameView
    }

    func updateNSView(_ nsView: EditorGameView, context: Context) { }
    
}

class EditorGameView: GameView {
    
    private(set) var worldGrid: WorldGrid!
    
    private(set) var mutableMap: EditorMapNode!
    
    let selectionModel: SelectionModel = SelectionModel()
    
    private var previousFrameTime: TimeInterval? = nil
    
    private(set) var selectionManager: SelectionManager?
    private var viewFrustrumShape: SKShapeNode?
    
    private let lightsRoot: SKNode
    private var lightEntities: [GKEntity] = []
    private(set) var ambientLightEntity: GKEntity? = nil
    
    private var editableComponents: GKComponentSystem = GKComponentSystem(componentClass: EditableComponent.self)
    
    var hoverableEntities: HoverableSequence { HoverableSequence(worldGrid.hoverableEntities, mutableMap.hoverableEntities, lightEntities) }
    
    override init(frame frameRect: CGRect) {
        lightsRoot = SKNode()
        lightsRoot.zPosition = 10000
        
        super.init(frame: frameRect)
        
        showsPhysics = true
        isAsynchronous = false
        
        worldGrid = WorldGrid()
        scene!.addChild(worldGrid)
    
        scene!.addChild(lightsRoot)
        
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
            viewFrustrumShape!.zPosition = 10001
            camera.addChild(viewFrustrumShape!)
        }
    }
    
    override func update(_ currentTime: TimeInterval, for scene: SKScene) {
        super.update(currentTime, for: scene)
        
        updateWorldGrid(for: scene)
        
        if let previousFrameTime = previousFrameTime {
            let deltaTime = currentTime - previousFrameTime
            editableComponents.update(deltaTime: deltaTime)
        }
        previousFrameTime = currentTime
        
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
    
    override func mouseDragged(with event: NSEvent) {
        nextResponder?.mouseDragged(with: event)
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
        mutableMap.increaseElevation(area: area)
        
        if let area = area {
            let selectable = map.lookForMapCellEntity(atX: area.x, y: area.y)?.findSelectableComponent()
            selectionModel.setSelectable(selectable)
        }
    }
    
    func decreaseElevation(area: MapArea?) {
        mutableMap.decreaseElevation(area: area)
        
        if area != nil {
            let selectable = map.lookForMapCellEntity(atX: area!.x, y: area!.y)?.findSelectableComponent()
            selectionModel.setSelectable(selectable)
        }
    }
    
    override func mapNode(from description: MapDescription) -> MapNode {
        mutableMap = EditorMapNode(description: description)
        return mutableMap
    }
    
    override func unloadMap(removePreviousMap: Bool = true) {
        super.unloadMap(removePreviousMap: removePreviousMap)
        selectionModel.clear()
        lightsRoot.removeAllChildren()
        lightEntities.removeAll()
        buildLightNodes()
    }
    
    override func loadMap(file: URL) {
        super.loadMap(file: file)
        selectionModel.clear()
        buildLightNodes()
    }
    
    override func prepareSceneForPrepasses() {
        super.prepareSceneForPrepasses()
        
        worldGrid.isHidden = true
        viewFrustrumShape?.isHidden = true
        lightsRoot.isHidden = true
    }
    
    override func prepassesDidComplete() {
        super.prepassesDidComplete()
        
        worldGrid.isHidden = false
        viewFrustrumShape?.isHidden = false
        lightsRoot.isHidden = false
    }
    
    func buildLightNodes() {
        if let lights = map.lights {
            for light in lights {
                let lightEntity = PointLightComponent.entity(from: light)
                if let lightNode = lightEntity.component(ofType: GKSKNodeComponent.self)?.node {
                    lightsRoot.addChild(lightNode)
                }
                lightEntities.append(lightEntity)
                editableComponents.addComponent(foundIn: lightEntity)
            }
        }
        
        ambientLightEntity = AmbientLightComponent.entity(from: map.ambientLight)
    }
    
}
