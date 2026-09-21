import SpriteKit
import GameplayKit
import Combine

public extension Notification.Name {
    static let addUiElementRequested: Self = .init(rawValue: "addUiElementRequested")
    static let addAssetInstanceRequested: Self = .init(rawValue: "addAssetInstanceRequested")

    static let mapCellPickRequested: Self = .init(rawValue: "mapCellPickRequested")
    static let mapCellPicked: Self = .init(rawValue: "mapCellPicked")

    static let assetPickRequeted: Self = .init(rawValue: "assetPickRequested")
    static let assetPicked: Self = .init(rawValue: "assetPicked")

    static let pointerDown: Self = .init(rawValue: "pointerDown")
    static let pointerUp: Self = .init(rawValue: "pointerUp")
    static let pointerMoved: Self = .init(rawValue: "pointerMoved")

    static let keyPressed: Self = .init(rawValue: "keyPressed")
}

open class GameView: LitSceneView {

    public nonisolated static let eventDataUserInfo = "eventData"
    public nonisolated static let newElement = "newElement"
    public nonisolated static let pickedMapCell = "pickedMapCell"
    public nonisolated static let pickedAsset = "pickedAsset"

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
    
    private var backdropPointerDown: AnyCancellable?
    private var backdropPointerUp: AnyCancellable?
    private var backdropPointerMoved: AnyCancellable?

    private var asyncListenerTask: Task<Void, Never>? = nil
    private var latestMapDescription: SendableRef<MapDescription>? = nil

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

        litNodesRoot.addChild(map)
        litNodesRoot.addChild(mapOverlay)

        backdropPointerDown = eventBackdropNode.pointerDown.sink { NotificationCenter.default.post(name: .pointerDown, object: self, userInfo: [Self.eventDataUserInfo: $0.eventData]) }
        backdropPointerUp = eventBackdropNode.pointerUp.sink { NotificationCenter.default.post(name: .pointerUp, object: self, userInfo: [Self.eventDataUserInfo: $0.eventData]) }
        backdropPointerMoved = eventBackdropNode.pointerMoved.sink { NotificationCenter.default.post(name: .pointerMoved, object: self, userInfo: [Self.eventDataUserInfo: $0.eventData]) }

        asyncListenerTask = setupAsyncListeners()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        asyncListenerTask?.cancel()
    }

    private func setupAsyncListeners() -> Task<Void, Never> {
        Task {
            await withThrowingTaskGroup { group in
                group.addTask {
                    for await newMapDescription in await MapModel.shared.updateStream {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.latestMapDescription = SendableRef(newMapDescription)
                        }
                    }
                }

                group.addTask {
                    for await newUINode in NotificationCenter.default.notifications(named: .addUiElementRequested).compactMap({ $0.userInfo?[Self.newElement] as? SKNode }) {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.uiOverlayCanvas.addChild(newUINode)
                        }
                    }
                }

                group.addTask {
                    for await newAssetInstanceNode in NotificationCenter.default.notifications(named: .addAssetInstanceRequested).compactMap({ $0.userInfo?[Self.newElement] as? SKNode }) {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.mapOverlay.addChild(newAssetInstanceNode)
                        }
                    }
                }

                group.addTask {
                    for await _ in NotificationCenter.default.notifications(named: .mapCellPickRequested) {
                        try Task.checkCancellation()
                        if let pickedCell = await self.pickMapCell() {
                            NotificationCenter.default.post(name: .mapCellPicked, object: self, userInfo: [Self.pickedMapCell: pickedCell])
                        }
                    }
                }

                group.addTask {
                    for await _ in NotificationCenter.default.notifications(named: .assetPickRequeted) {
                        try Task.checkCancellation()
                        if let pickedAsset = await self.pickAsset() {
                            NotificationCenter.default.post(name: .assetPicked, object: self, userInfo: [Self.pickedAsset: pickedAsset])
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
        NotificationCenter.default.post(name: .keyPressed, object: self, userInfo: [Self.eventDataUserInfo: KeyEventData(with: event)])
    }
#endif // os(macOS)

    private func pickMapCell() async -> MapCellComponent? {
        var pointerUpEventData: PointerEventData? = nil

        for await eventData in NotificationCenter.default.notifications(named: .pointerUp).map({ $0.userInfo?[Self.eventDataUserInfo] as? PointerEventData }) {
            pointerUpEventData = eventData
            break
        }

        let locationInScene = gameScene.convertPoint(fromView: pointerUpEventData!.pointInView)
        return map.raycastMapCell(at: locationInScene)
    }

    private func pickAsset() async -> AssetComponent? {
        var pointerUpEventData: PointerEventData? = nil

        for await eventData in NotificationCenter.default.notifications(named: .pointerUp).map({ $0.userInfo?[Self.eventDataUserInfo] as? PointerEventData }) {
            pointerUpEventData = eventData
            break
        }

        let locationInScene = gameScene.convertPoint(fromView: pointerUpEventData!.pointInView)
        return map.raycastAsset(at: locationInScene)
    }

    public nonisolated static func notificationToPointerEventData(_ notif: NotificationCenter.Notifications.Element) -> GameViewPointerEventData? {
        guard
            let gameView = notif.object as? GameView,
            let eventData = notif.userInfo?[GameView.eventDataUserInfo] as? PointerEventData
        else {
            return nil
        }

        return (eventData, gameView)
    }

    public nonisolated static func notificationToKeyEventData(_ notif: NotificationCenter.Notifications.Element) -> GameViewKeyEventData? {
        guard
            let gameView = notif.object as? GameView,
            let eventData = notif.userInfo?[GameView.eventDataUserInfo] as? KeyEventData
        else {
            return nil
        }

        return (eventData, gameView)
    }

}
