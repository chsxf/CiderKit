import SpriteKit
import GameplayKit

open class GameView: SKView, SKSceneDelegate {

    internal var gameScene: SKScene!
    
    private var finalGatheringNode: SKEffectNode!
    
    public private(set) var map: MapNode!
    
    private var normalsTexture: SKTexture?
    private var positionTexture: SKTexture?
    
    public var lightingEnabled: Bool = true
    
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
        
        finalGatheringNode = SKEffectNode();
        finalGatheringNode.shader = CiderKitEngine.lightModelFinalGatheringShader
        finalGatheringNode.shouldEnableEffects = false
        gameScene.addChild(finalGatheringNode)
        
        presentScene(gameScene)
        
        unloadMap(removePreviousMap: false)
      
        registerDefaultMaterialsAndRenderers()
        
        #if os(macOS)
        NotificationCenter.default.addObserver(self, selector: #selector(Self.updateSceneSize), name: NSView.frameDidChangeNotification, object: self)
        #endif
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func registerDefaultMaterialsAndRenderers() {
        let url = CiderKitEngine.bundle.url(forResource: "Default Materials", withExtension: "ckmatdb")
        let _: Materials = try! Functions.load(url!)
        
        let defaultRenderer = CellRenderer(
            groundMaterialName: "default_ground",
            leftElevationMaterialName: "default_elevation_left",
            rightElevationMaterialName: "default_elevation_right"
        )
        try! CellRenderers.register(cellRenderer: defaultRenderer, named: "default_cell")
    }
    
    open func mapNode(from description: MapDescription) -> MapNode {
        return MapNode(description: description)
    }
    
    open func update(_ currentTime: TimeInterval, for scene: SKScene) { }
    
    open func prepareSceneForPrepasses() {
        finalGatheringNode.shouldEnableEffects = false
    }
    
    open func prepassesDidComplete() {
        finalGatheringNode.shouldEnableEffects = true
    }
    
    private func computePositionMatrix() -> matrix_float3x3 {
        var minVector = vector_float3(Float.infinity, Float.infinity, 0)
        var maxVector = vector_float3(-Float.infinity, -Float.infinity, 0)
        
        for region in map.regions {
            let area = region.regionDescription.area
            
            minVector.x = min(minVector.x, Float(area.minX))
            minVector.y = min(minVector.y, Float(area.minY))
            
            maxVector.x = max(maxVector.x, Float(area.maxX))
            maxVector.y = max(maxVector.y, Float(area.maxY))
            maxVector.z = max(maxVector.z, Float(region.regionDescription.elevation + 1) * 0.25)
        }
        
        return matrix_float3x3(minVector, maxVector, vector_float3())
    }
    
    open func didFinishUpdate(for scene: SKScene) {
        let positionMatrix = computePositionMatrix()
        
        CiderKitEngine.setUberShaderPositionRanges(positionMatrix)
        
        prepareSceneForPrepasses()
        #if os(macOS)
        let viewBottomLeftInScene = convert(CGPoint(), to: scene)
        let viewTopRightInScene = convert(CGPoint(x: frame.maxX, y: frame.maxY), to: scene)
        let viewWidthInScene = viewTopRightInScene.x - viewBottomLeftInScene.x
        let viewHeightInScene = viewTopRightInScene.y - viewBottomLeftInScene.y
        let viewRectInScene = CGRect(origin: viewBottomLeftInScene, size: CGSize(width: viewWidthInScene, height: viewHeightInScene))

        CiderKitEngine.setUberShaderShadeMode(.normals)
        normalsTexture = texture(from: scene, crop: viewRectInScene)
        CiderKitEngine.setUberShaderShadeMode(.position)
        positionTexture = texture(from: scene, crop: viewRectInScene)
        CiderKitEngine.setUberShaderShadeMode(.default)
        #else
        CiderKitEngine.setUberShaderShadeMode(.normals)
        normalsTexture = texture(from: scene)
        CiderKitEngine.setUberShaderShadeMode(.position)
        positionTexture = texture(from: scene)
        CiderKitEngine.setUberShaderShadeMode(.default)
        #endif
        prepassesDidComplete()
        
        let finalGatherRect = finalGatheringNode.calculateAccumulatedFrame()
        let finalGatherMinInView = convert(finalGatherRect.origin, from: scene)
        let finalGatherMaxInView = convert(CGPoint(x: finalGatherRect.maxX, y: finalGatherRect.maxY), from: scene)
        let finalGatherViewNormalizedMinX = Float(finalGatherMinInView.x / frame.width)
        let finalGatherViewNormalizedMinY = Float(finalGatherMinInView.y / frame.height)
        let finalGatherViewNormalizedMaxX = Float(finalGatherMaxInView.x / frame.width)
        let finalGatherViewNormalizedMaxY = Float(finalGatherMaxInView.y / frame.height)

        if let uniform = CiderKitEngine.lightModelFinalGatheringShader.uniformNamed(CiderKitEngine.ShaderUniformName.frameInViewSpace.rawValue) {
            #if os(iOS) || os(tvOS)
            let matrix = matrix_float2x2([vector_float2(finalGatherViewNormalizedMinX, 1.0 - finalGatherViewNormalizedMinY), vector_float2(finalGatherViewNormalizedMaxX, 1.0 - finalGatherViewNormalizedMaxY)])
            #else
            let matrix = matrix_float2x2([vector_float2(finalGatherViewNormalizedMinX, finalGatherViewNormalizedMinY), vector_float2(finalGatherViewNormalizedMaxX, finalGatherViewNormalizedMaxY)])
            #endif
            
            uniform.matrixFloat2x2Value = matrix
        }
        if let uniform = CiderKitEngine.lightModelFinalGatheringShader.uniformNamed(CiderKitEngine.ShaderUniformName.positionTexture.rawValue) {
            uniform.textureValue = positionTexture
        }
        if let uniform = CiderKitEngine.lightModelFinalGatheringShader.uniformNamed(CiderKitEngine.ShaderUniformName.normalsTexture.rawValue) {
            uniform.textureValue = normalsTexture
        }
        if let uniform = CiderKitEngine.lightModelFinalGatheringShader.uniformNamed(CiderKitEngine.ShaderUniformName.positionRanges.rawValue) {
            uniform.matrixFloat3x3Value = positionMatrix
        }

        if let uniform = CiderKitEngine.lightModelFinalGatheringShader.uniformNamed(CiderKitEngine.ShaderUniformName.ambientLight.rawValue) {
            uniform.vectorFloat3Value = lightingEnabled ? map.ambientLight.vector : vector_float3(1, 1, 1)
        }
        
        let definedLightCount = map.lights.count
        for lightIndex in 0...CiderKitEngine.ShaderUniformName.maxLightIndex {
            guard
                let lightUniformName = CiderKitEngine.ShaderUniformName(lightIndex: lightIndex),
                let uniform = CiderKitEngine.lightModelFinalGatheringShader.uniformNamed(lightUniformName.rawValue)
            else {
                break
            }
            let lightMatrix = (lightingEnabled && lightIndex < definedLightCount) ? map.lights[lightIndex].matrix : matrix_float3x3();
            uniform.matrixFloat3x3Value = lightMatrix
        }
    }
    
    open func loadMap(file: URL) {
        do {
            let mapDescription: MapDescription = try Functions.load(file)
            unloadMap()
            map = mapNode(from: mapDescription)
            finalGatheringNode.addChild(map!)
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
        finalGatheringNode.addChild(map)
    }
    
    #if os(macOS)
    @objc
    private func updateSceneSize() {
        let sceneWidth = Project.current?.settings.targetResolutionWidth ?? 640
        let sceneHeight = Project.current?.settings.targetResolutionHeight ?? 360
        let sceneSize = getBestMatchingSceneSize(CGSize(width: sceneWidth, height: sceneHeight))
        scene?.size = sceneSize
    }
    #endif
    
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
