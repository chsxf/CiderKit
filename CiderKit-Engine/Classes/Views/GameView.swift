import SpriteKit
import GameplayKit
import Combine

open class GameView: LitSceneView {

    public typealias GameViewPointerEventData = (eventData: PointerEventData, sender: GameView)
    public typealias GameViewKeyEventData = (eventData: KeyEventData, sender: GameView)

    public let map: MapNode
    public let mapOverlay: SKNode

#if os(macOS)
    private var trackingAreaManager: TrackingAreaManager!
#endif
    private var eventBackdropNode: EventBackdropNode!
    public let uiOverlayCanvas: CKUICanvas
    
    public var lightingEnabled: Bool = true
    
    open override var ambientLightColorRGB: SIMD3<Float> {
        get {
            guard lightingEnabled else {
                return super.ambientLightColorRGB
            }
            return MapModel.shared.ambientLight.colorVector
        }
    }
    
    open override var preferredSceneWidth: Int { Project.current?.settings.targetResolutionWidth ?? super.preferredSceneWidth }
    open override var preferredSceneHeight: Int { Project.current?.settings.targetResolutionHeight ?? super .preferredSceneHeight }
    
    private let pointerDownSubject = PassthroughSubject<GameViewPointerEventData, Never>()
    public let pointerDown: AsyncPublisher<PassthroughSubject<GameViewPointerEventData, Never>>
    private let pointerUpSubject = PassthroughSubject<GameViewPointerEventData, Never>()
    public let pointerUp: AsyncPublisher<PassthroughSubject<GameViewPointerEventData, Never>>
    private let pointerMovedSubject = PassthroughSubject<GameViewPointerEventData, Never>()
    public let pointerMoved: AsyncPublisher<PassthroughSubject<GameViewPointerEventData, Never>>

    private let keyPressedSubject = PassthroughSubject<GameViewKeyEventData, Never>()
    public let keyPressed: AsyncPublisher<PassthroughSubject<GameViewKeyEventData, Never>>

    private var backdropPointerDown: AnyCancellable?
    private var backdropPointerUp: AnyCancellable?
    private var backdropPointerMoved: AnyCancellable?

    private var mapDescriptionUpdateListenerTask: Task<Void, Never>? = nil
    private var latestMapDescription: MapDescription? = nil

    public override init(frame frameRect: CGRect) {
        let defaultStyleSheetURL = CiderKitEngine.bundle.url(forResource: "Default Style Sheet", withExtension: "ckcss")!
        let styleSheet = try! CKUIStyleSheet(contentsOf: defaultStyleSheetURL)
        if let currentProject = Project.current, let projectStyleSheets = currentProject.settings.styleSheets {
            for styleSheetName in projectStyleSheets {
                let styleSheetURL = URL(fileURLWithPath: "\(styleSheetName).ckcss", isDirectory: false, relativeTo: Project.current!.styleSheetsDirectoryURL)
                try! styleSheet.addStyleSheet(contentsOf: styleSheetURL)
            }
        }
        uiOverlayCanvas = CKUICanvas(styleSheet: styleSheet)

        mapOverlay = SKNode()
        mapOverlay.zPosition = 100

        pointerDown = AsyncPublisher(pointerDownSubject)
        pointerUp = AsyncPublisher(pointerUpSubject)
        pointerMoved = AsyncPublisher(pointerMovedSubject)

        keyPressed = AsyncPublisher(keyPressedSubject)

        map = Self.mapNode()

        super.init(frame: frameRect)

        showsFPS = true
        showsDrawCount = true
        showsNodeCount = true
        ignoresSiblingOrder = true
        allowsTransparency = true
        
#if os(macOS)
        trackingAreaManager = .init(scene: gameScene)
#endif

        uiOverlayCanvas.zIndex = 1000
        eventBackdropNode = .init()
        eventBackdropNode.zPosition = CGFloat(uiOverlayCanvas.zIndex - 1)

        camera.addChild(eventBackdropNode)
        camera.addChild(uiOverlayCanvas)

        litNodesRoot.addChild(mapOverlay)

        backdropPointerDown = eventBackdropNode.pointerDown.sink { self.pointerDownSubject.send(($0.eventData, self)) }
        backdropPointerUp = eventBackdropNode.pointerUp.sink { self.pointerUpSubject.send(($0.eventData, self)) }
        backdropPointerMoved = eventBackdropNode.pointerMoved.sink { self.pointerMovedSubject.send(($0.eventData, self)) }

        mapDescriptionUpdateListenerTask = setupMapDescriptionUpdateListener()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        mapDescriptionUpdateListenerTask?.cancel()
    }

    private func setupMapDescriptionUpdateListener() -> Task<Void, Never> {
        Task {
            await withThrowingTaskGroup { group in
                group.addTask {
                    for await newMapDescription in await MapModel.shared.updateStream {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.latestMapDescription = newMapDescription
                        }
                    }
                }
            }
        }
    }

    open class func mapNode() -> MapNode {
        MapNode()
    }

    open override func update(_ currentTime: TimeInterval, for scene: SKScene) {
        if let latestMapDescription {
            map.match(mapDescription: latestMapDescription)
        }

        super.update(currentTime, for: scene)
        
#if os(macOS)
        trackingAreaManager.update()
#endif

        eventBackdropNode.size = scene.size
        uiOverlayCanvas.update()
    }
    
    open override func prepareSceneForPrepasses() {
        super.prepareSceneForPrepasses()
        uiOverlayCanvas.isHidden = true
    }
    
    open override func prepassesDidComplete() {
        super.prepassesDidComplete()
        uiOverlayCanvas.isHidden = false
    }
    
    open override func computePositionMatrix() -> matrix_float3x3 {
        var minVector = WorldPosition(Float.infinity, Float.infinity, 0)
        var maxVector = WorldPosition(-Float.infinity, -Float.infinity, 0)

        if let mapDescription = map.mapDescription {
            for region in mapDescription.regions {
                let area = region.area

                minVector.x = min(minVector.x, Float(area.minX))
                minVector.y = min(minVector.y, Float(area.minY))

                maxVector.x = max(maxVector.x, Float(area.maxX))
                maxVector.y = max(maxVector.y, Float(area.maxY))
                maxVector.z = max(maxVector.z, Float(region.elevation + 1))
            }
        }

        return matrix_float3x3(minVector, maxVector, SIMD3())
    }
    
    open override func getLightMatrix(_ index: Int) -> matrix_float3x3 {
        let mapModel = MapModel.shared
        guard lightingEnabled,
              index < mapModel.lights.count
        else {
            return super.getLightMatrix(index)
        }

        return mapModel.lights[index].matrix
    }

#if os(macOS)
    open override func otherMouseDown(with event: NSEvent) {
        firstInteractiveNode(from: event)?.otherMouseDown(with: event)
    }

    open override func otherMouseUp(with event: NSEvent) {
        firstInteractiveNode(from: event)?.otherMouseUp(with: event)
    }

    open override func keyDown(with event: NSEvent) {
        keyPressedSubject.send((KeyEventData(with: event), self))
    }
#endif // os(macOS)

    public func pickMapCell() async -> MapCellComponent? {
        return await Task {
            var pointerUpEventData: PointerEventData? = nil

            for await (eventData, _) in pointerUp {
                pointerUpEventData = eventData
                break
            }

            let locationInScene = gameScene.convertPoint(fromView: pointerUpEventData!.pointInView)
            return map.raycastMapCell(at: locationInScene)
        }.value
    }

    public func pickAsset() async -> AssetComponent? {
        return await Task {
            var pointerUpEventData: PointerEventData? = nil

            for await (eventData, _) in pointerUp {
                pointerUpEventData = eventData
                break
            }

            let locationInScene = gameScene.convertPoint(fromView: pointerUpEventData!.pointInView)
            return map.raycastAsset(at: locationInScene)
        }.value
    }

}
