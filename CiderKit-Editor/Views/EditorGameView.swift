import CoreFoundation
import SpriteKit
import GameplayKit
import CiderKit_Engine

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
            let selectable = map.lookForMapCellEntity(atMapPosition: MapPosition(x: area.x, y: area.y))?.findSelectableComponent()
            selectionModel.setSelectable(selectable)
        }
    }
    
    func decreaseElevation(area: MapArea?) {
        mutableMap.decreaseElevation(area: area)
        
        if let area {
            let selectable = map.lookForMapCellEntity(atMapPosition: MapPosition(x: area.x, y: area.y))?.findSelectableComponent()
            selectionModel.setSelectable(selectable)
        }
    }
    
    override func mapNode(from description: MapDescription) -> MapNode {
        mutableMap = EditorMapNode(description: description)
        return mutableMap
    }
    
    override func unloadMap(removePreviousMap: Bool = true) {
        selectionModel.clear()
        super.unloadMap(removePreviousMap: removePreviousMap)
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
        selectionManager?.hideTools()
    }
    
    override func prepassesDidComplete() {
        super.prepassesDidComplete()
        
        worldGrid.isHidden = false
        viewFrustrumShape?.isHidden = false
        lightsRoot.isHidden = false
        selectionManager?.showTools()
    }
    
    private func buildLightNodes() {
        map.lights.forEach { setupPointLight($0) }
        ambientLightEntity = AmbientLightComponent.entity(from: map.ambientLight)
    }
    
    private func setupPointLight(_ light: PointLight) {
        let lightEntity = PointLightComponent.entity(from: light)
        if let lightNode = lightEntity.component(ofType: GKSKNodeComponent.self)?.node {
            lightsRoot.addChild(lightNode)
        }
        lightEntities.append(lightEntity)
        editableComponents.addComponent(foundIn: lightEntity)
        
        if let pointLightComponent = lightEntity.component(ofType: PointLightComponent.self) {
            NotificationCenter.default.addObserver(self, selector: #selector(pointLightErased(notification:)), name: .selectableErased, object: pointLightComponent)
        }
    }
    
    func add(light: PointLight) {
        mutableMap.add(light: light)
        setupPointLight(light)
    }
    
    func addAsset(_ asset: AssetLocator, atMapPosition position: MapPosition, horizontallyFlipped: Bool) {
        do {
            try mutableMap.addAsset(asset, named: "", atMapPosition: position, horizontallyFlipped: horizontallyFlipped)
            mutableMap.dirty = true
        }
        catch MapRegionErrors.assetTooCloseToRegionBorder {
            let alert = NSAlert()
            alert.informativeText = "Error"
            alert.messageText = "Unable to place asset - Too close to the region's borders"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        catch MapRegionErrors.otherAssetInTheWay {
            let alert = NSAlert()
            alert.informativeText = "Error"
            alert.messageText = "Unable to place asset - Another asset already exists in the target area"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        catch {
            let alert = NSAlert()
            alert.informativeText = "Error"
            alert.messageText = "Unexpected error: \(error)"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    @objc
    private func pointLightErased(notification: Notification) {
        if let pointLightComponent = notification.object as? PointLightComponent {
            NotificationCenter.default.removeObserver(self, name: .selectableErased, object: pointLightComponent)
            
            mutableMap.remove(light: pointLightComponent.lightDescription)
            
            let lightEntity = pointLightComponent.entity!
            lightEntity.component(ofType: GKSKNodeComponent.self)!.node.removeFromParent()
            lightEntities.removeAll { $0 === lightEntity }
            editableComponents.removeComponent(foundIn: lightEntity)
        }
    }
    
}
