import SpriteKit
import GameplayKit

open class GameView: LitSceneView {

    public private(set) var map: MapNode!

    private let eventBackdropNode = EventBackdropNode()
    public let uiOverlayCanvas: CKUICanvas
    
    public var lightingEnabled: Bool = true
    
    open override var ambientLightColorRGB: SIMD3<Float> {
        lightingEnabled ? map.ambientLight.vector : super.ambientLightColorRGB
    }
    
    open override var preferredSceneWidth: Int { Project.current?.settings.targetResolutionWidth ?? super.preferredSceneWidth }
    open override var preferredSceneHeight: Int { Project.current?.settings.targetResolutionHeight ?? super .preferredSceneHeight }
    
    public let pointerDown = EventEmitter<PointerEventData, GameView>()
    public let pointerUp = EventEmitter<PointerEventData, GameView>()
    public let pointerMoved = EventEmitter<PointerEventData, GameView>()

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
        
        super.init(frame: frameRect)

        showsFPS = true
        showsDrawCount = true
        showsNodeCount = true
        ignoresSiblingOrder = true
        allowsTransparency = true
        
        uiOverlayCanvas.zPosition = 1000
        eventBackdropNode.zPosition = uiOverlayCanvas.zPosition - 1

        camera.addChild(eventBackdropNode)
        camera.addChild(uiOverlayCanvas)
        
        unloadMap(removePreviousMap: false)
        
        #if os(macOS)
        TrackingAreaManager.scene = gameScene
        #endif

        eventBackdropNode.pointerDown.on { eventData, _ in self.pointerDown.notify(eventData, from: self) }
        eventBackdropNode.pointerUp.on { eventData, _ in self.pointerUp.notify(eventData, from: self) }
        eventBackdropNode.pointerMoved.on { eventData, _ in self.pointerMoved.notify(eventData, from: self) }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func mapNode(from description: MapDescription) -> MapNode {
        return MapNode(description: description)
    }
    
    open override func update(_ currentTime: TimeInterval, for scene: SKScene) {
        super.update(currentTime, for: scene)
        
        #if os(macOS)
        TrackingAreaManager.update()
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
        
        for region in map.regions {
            let area = region.regionDescription.area
            
            minVector.x = min(minVector.x, Float(area.minX))
            minVector.y = min(minVector.y, Float(area.minY))
            
            maxVector.x = max(maxVector.x, Float(area.maxX))
            maxVector.y = max(maxVector.y, Float(area.maxY))
            maxVector.z = max(maxVector.z, Float(region.regionDescription.elevation + 1))
        }
        
        return matrix_float3x3(minVector, maxVector, SIMD3())
    }
    
    open func loadMap(file: URL) {
        do {
            let mapDescription: MapDescription = try Functions.load(file)
            unloadMap()
            map = mapNode(from: mapDescription)
            litNodesRoot.addChild(map!)
        }
        catch {
            let title = "Error"
            let message = "Unable to load map file at \(file)"
            
            #if os(macOS)
            let alert = NSAlert()
            alert.informativeText = title
            alert.messageText = message
            alert.addButton(withTitle: "OK")
            let _ = alert.runModal()
            #else
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.findViewController()?.present(alert, animated: true, completion: nil)
            #endif
        }
    }
    
    open func unloadMap(removePreviousMap: Bool = true) {
        if removePreviousMap {
            map.removeFromParent()
        }
        
        let mapDescription = MapDescription()
        map = mapNode(from: mapDescription)
        litNodesRoot.addChild(map)
    }
    
    open override func getLightMatrix(_ index: Int) -> matrix_float3x3 {
        guard lightingEnabled, index < map.lights.count else {
            return super.getLightMatrix(index)
        }
        return map.lights[index].matrix
    }

    #if os(macOS)
    open override func otherMouseDown(with event: NSEvent) {
        firstInteractiveNode(from: event)?.otherMouseDown(with: event)
    }

    open override func otherMouseUp(with event: NSEvent) {
        firstInteractiveNode(from: event)?.otherMouseUp(with: event)
    }
    #endif

    public func pickMapCell() async -> MapCellComponent? {
        var pointerUpEventData: PointerEventData? = nil

        pointerUp.once { eventData, _ in
            if eventData.mouseButtonIndex == 0 {
                pointerUpEventData = eventData
            }
        }

        let task = Task {
            while true {
                await Task.yield()
                if pointerUpEventData != nil {
                    break
                }
            }

            let locationInScene = gameScene.convertPoint(fromView: pointerUpEventData!.pointInView)
            return map.raycastMapCell(at: locationInScene)
        }
        return await task.value
    }

    public func pickAsset() async -> AssetComponent? {
        var pointerUpEventData: PointerEventData? = nil

        pointerUp.once { eventData, _ in
            if eventData.mouseButtonIndex == 0 {
                pointerUpEventData = eventData
            }
        }

        let task = Task {
            while true {
                await Task.yield()
                if pointerUpEventData != nil {
                    break
                }
            }

            let locationInScene = gameScene.convertPoint(fromView: pointerUpEventData!.pointInView)
            return map.raycastAsset(at: locationInScene)
        }
        return await task.value
    }

}
