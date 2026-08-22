import CoreFoundation
import SpriteKit
import GameplayKit
import CiderKit_Engine

class EditorGameView: RuntimeGameView {
    
    private(set) var worldGrid: WorldGrid!
    
    public private(set) var mutableMap: EditorMapNode!

    let selectionModel: SelectionModel = SelectionModel()
    
    private var previousFrameTime: TimeInterval? = nil
    
    private(set) var selectionManager: SelectionManager?
    private var viewFrustrumShape: SKShapeNode?
    
    private let lightIconsRoot: SKNode
    private var lightEntities: [GKEntity] = []
    private(set) var ambientLightEntity: GKEntity? = nil
    
    private var editableComponents: GKComponentSystem = GKComponentSystem(componentClass: EditableComponent.self)
    
    private var notificationTask: Task<Void, Never>? = nil
    
    var hoverableEntities: HoverableSequence { HoverableSequence(worldGrid.hoverableEntities, mutableMap.hoverableEntities, lightEntities) }

    override init(frame frameRect: CGRect) {
        lightIconsRoot = SKNode()
        lightIconsRoot.zPosition = 10000
        
        super.init(frame: frameRect)

        mutableMap = (map as! EditorMapNode)

        isAsynchronous = false
        
        worldGrid = WorldGrid()
        scene!.addChild(worldGrid)
    
        scene!.addChild(lightIconsRoot)
        
        updateViewFrustrum()

        ambientLightEntity = AmbientLightComponent.entity(from: lighting.ambientLight)

        notificationTask = setupNotifications()

        Task { @MainActor in
            self.selectionManager = SelectionManager(editorGameView: self)
            self.nextResponder = self.selectionManager
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        notificationTask?.cancel()
    }
    
    private func setupNotifications() -> Task<Void, Never> {
        Task {
            await withThrowingTaskGroup { group in
                group.addTask {
                    for await _ in NotificationCenter.default.notifications(named: ProjectManager.projectOpened) {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.updateViewFrustrum()
                            self.viewDidEndLiveResize()
                        }
                    }
                }

                group.addTask {
                    for await lightImplementation in await self.lighting.lightAdded {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.setup(light: lightImplementation)
                        }
                    }
                }

                group.addTask {
                    for await lightImplementation in await self.lighting.lightRemoved {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.remove(light: lightImplementation)
                        }
                    }
                }
            }
        }
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
    
    func increaseElevation(area: MapArea?) async {
        selectionModel.clear()
        await MapModel.shared.increaseElevation(area: area)
    }
    
    func decreaseElevation(area: MapArea?) async {
        selectionModel.clear()
        await MapModel.shared.decreaseElevation(area: area)
    }
    
    override class func mapNode() -> MapNode {
        EditorMapNode()
    }

    override func prepareSceneForPrepasses() {
        super.prepareSceneForPrepasses()
        
        worldGrid.isHidden = true
        viewFrustrumShape?.isHidden = true
        lightIconsRoot.isHidden = true
        selectionManager?.hideTools()
    }
    
    override func prepassesDidComplete() {
        super.prepassesDidComplete()
        
        worldGrid.isHidden = false
        viewFrustrumShape?.isHidden = false
        lightIconsRoot.isHidden = false
        selectionManager?.showTools()
    }
    
    func setup(light: any LightImplementation) {
        if let pointLight = light as? PointLight {
            setup(lightEntity: PointLightComponent.entity(from: pointLight))
        }
        else if let directionalLight = light as? DirectionalLight {
            setup(lightEntity: DirectionalLightComponent.entity(from: directionalLight))
        }
    }

    private func setup(lightEntity: GKEntity) {
        if let lightNode = lightEntity.component(ofType: GKSKNodeComponent.self)?.node {
            lightIconsRoot.addChild(lightNode)
        }
        lightEntities.append(lightEntity)
        editableComponents.addComponent(foundIn: lightEntity)
    }

    private func remove(light: any LightImplementation) {
        if light is PointLight {
            remove(light: PointLight.self, with: PointLightComponent.self)
        }
        else if light is DirectionalLight {
            remove(light: DirectionalLight.self, with: DirectionalLightComponent.self)
        }
    }

    private func remove<ComponentType, LightType>(light: LightType.Type, with componentType: ComponentType.Type) where ComponentType: GKComponent & BaseLightComponent, LightType: LightImplementation {
        guard
            let lightEntity = lightEntities.first(where: { $0.component(ofType: componentType)?.lightImplementation === light }),
            let sknodeComponent = lightEntity.component(ofType: GKSKNodeComponent.self)
        else {
            return
        }

        sknodeComponent.node.removeFromParent()
        editableComponents.removeComponent(foundIn: lightEntity)
        lightEntities.removeAll { $0 === lightEntity }
    }

    func addAsset(_ asset: AssetLocator, atMapPosition position: MapPosition, horizontallyFlipped: Bool) async {
        do {
            try await mutableMap?.addAsset(asset, named: "", at: position, horizontallyFlipped: horizontallyFlipped)
            mutableMap?.dirty = true
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
    
}
