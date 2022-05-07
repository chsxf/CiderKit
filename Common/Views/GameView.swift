import SpriteKit
import GameplayKit

public class GameView: SKView, SKSceneDelegate {

    internal var gameScene: SKScene!
    
    private(set) var map: MapNode!
    
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
      
        registerDefaultMaterialsAndRenderers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func registerDefaultMaterialsAndRenderers() {
        let defaultGroundMaterial = BaseMaterial(sprites: [ Atlases.main["default_tile"]!, Atlases.main["default_tile_green"]! ])
        try! Materials.register(material: defaultGroundMaterial, forName: "default_ground")
        
        let defaultLeftElevationMaterial = BaseMaterial(sprite: Atlases.main["default_elevation_left"]!)
        try! Materials.register(material: defaultLeftElevationMaterial, forName: "default_elevation_left")
        
        let defaultRightElevationMaterial = BaseMaterial(sprite: Atlases.main["default_elevation_right"]!)
        try! Materials.register(material: defaultRightElevationMaterial, forName: "default_elevation_right")
        
        let defaultRenderer = CellRenderer(
            groundMaterialName: "default_ground",
            leftElevationMaterialName: "default_elevation_left",
            rightElevationMaterialName: "default_elevation_right"
        )
        try! CellRenderers.register(cellRenderer: defaultRenderer, forName: "default_cell")
    }
    
    public func update(_ currentTime: TimeInterval, for scene: SKScene) { }
    
    public func loadMap(file: URL) {
        do {
            let mapDescription: MapDescription = try Functions.load(file)
            unloadMap()
            map = MapNode(description: mapDescription)
            gameScene.addChild(map!)
        }
        catch {
            let alert = NSAlert()
            alert.informativeText = "Error"
            alert.messageText = "Unable to load map file at \(file)"
            alert.addButton(withTitle: "OK")
            let _ = alert.runModal()
        }
    }
    
    public func unloadMap(removePreviousMap: Bool = true) {
        if removePreviousMap {
            map.removeFromParent()
        }
        
        let mapDescription = MapDescription()
        map = MapNode(description: mapDescription)
        gameScene.addChild(map)
    }
    
    override public func viewDidEndLiveResize() {
        let sceneWidth = Project.current?.settings.targetResolutionWidth ?? 640
        let sceneHeight = Project.current?.settings.targetResolutionHeight ?? 360
        let sceneSize = getBestMatchingSceneSize(CGSize(width: sceneWidth, height: sceneHeight))
        scene?.size = sceneSize
    }
    
    public func getBestMatchingSceneSize(_ size: CGSize) -> CGSize {
        let baseAspectRatio = size.width / size.height
        let viewAspectRatio = frame.width / frame.height
        
        var resultSize = size
        if viewAspectRatio > baseAspectRatio {
            resultSize.width = (resultSize.height * viewAspectRatio).rounded(.awayFromZero)
        }
        else {
            resultSize.height = (resultSize.width / viewAspectRatio).rounded(.awayFromZero)
        }
        return resultSize
    }
    
}
