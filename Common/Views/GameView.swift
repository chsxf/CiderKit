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
      
        initDefaultMaterials()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initDefaultMaterials() {
        let defaultGroundMaterial = BaseMaterial(sprite: Atlases.main["default_tile"])
        try! Materials.register(material: defaultGroundMaterial, forName: "default_ground")
        
        let defaultLeftElevationMaterial = BaseMaterial(sprite: Atlases.main["default_elevation_left"])
        try! Materials.register(material: defaultLeftElevationMaterial, forName: "default_elevation_left")
        
        let defaultRightElevationMaterial = BaseMaterial(sprite: Atlases.main["default_elevation_right"])
        try! Materials.register(material: defaultRightElevationMaterial, forName: "default_elevation_right")
    }
    
    public func update(_ currentTime: TimeInterval, for scene: SKScene) { }
    
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
