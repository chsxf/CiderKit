import SpriteKit
import GameplayKit

open class LitSceneView: SKView, SKSceneDelegate {

    public let gameScene: SKScene
    public let litNodesRoot: SKNode
    public let camera: SKCameraNode
    
    open var ambientLightColorRGB: SIMD3<Float> { SIMD3(1, 1, 1) }
    
    open var preferredSceneWidth: Int { 640 }
    open var preferredSceneHeight: Int { 360 }
    
    private let finalGatheringSprite: SKSpriteNode
    
    private var albedoTexture: SKTexture?
    private var normalsTexture: SKTexture?
    private var positionTexture: SKTexture?
    
    public override init(frame frameRect: CGRect) {
        let scene = SKScene(size: frameRect.size)
        self.gameScene = scene
        
        litNodesRoot = SKNode()
        litNodesRoot.isHidden = true
        gameScene.addChild(litNodesRoot)
        
        camera = SKCameraNode()
        gameScene.camera = camera
        gameScene.addChild(camera)
        
        finalGatheringSprite = SKSpriteNode(texture: CiderKitEngine.clearTexture)
        finalGatheringSprite.shader = CiderKitEngine.lightModelFinalGatheringShader
        finalGatheringSprite.isHidden = true
        gameScene.addChild(finalGatheringSprite)
        
        super.init(frame: frameRect)

        gameScene.delegate = self
        
        showsFPS = true
        showsDrawCount = true
        showsNodeCount = true
        ignoresSiblingOrder = true
        allowsTransparency = true
        
        presentScene(gameScene)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func prepareSceneForPrepasses() {
        finalGatheringSprite.isHidden = true
        litNodesRoot.isHidden = false
    }
    
    open func prepassesDidComplete() {
        finalGatheringSprite.isHidden = false
        litNodesRoot.isHidden = true
    }
    
    open func computePositionMatrix() -> matrix_float3x3 { matrix_float3x3() }
    
    open func update(_ currentTime: TimeInterval, for scene: SKScene) {
        updateSceneSize()
    }
    
    public func didFinishUpdate(for scene: SKScene) {
        let positionMatrix = computePositionMatrix()
        CiderKitEngine.setUberShaderPositionRanges(positionMatrix)
        
        let previousBackgroundColor = scene.backgroundColor
        prepareSceneForPrepasses()
        scene.backgroundColor = SKColor.clear

        let viewBottomLeftInScene = convert(CGPoint(), to: scene)
        let viewTopRightInScene = convert(CGPoint(x: frame.maxX, y: frame.maxY), to: scene)
        let viewWidthInScene = viewTopRightInScene.x - viewBottomLeftInScene.x
        let viewHeightInScene = viewTopRightInScene.y - viewBottomLeftInScene.y
        let viewRectInScene = CGRect(origin: viewBottomLeftInScene, size: CGSize(width: viewWidthInScene, height: viewHeightInScene))

        CiderKitEngine.setUberShaderShadeMode(.default)
        albedoTexture = texture(from: scene, crop: viewRectInScene)
        albedoTexture?.filteringMode = .nearest
        CiderKitEngine.setUberShaderShadeMode(.normals)
        normalsTexture = texture(from: scene, crop: viewRectInScene)
        normalsTexture?.filteringMode = .nearest
        CiderKitEngine.setUberShaderShadeMode(.position)
        positionTexture = texture(from: scene, crop: viewRectInScene)
        positionTexture?.filteringMode = .nearest
        
        prepassesDidComplete()
        scene.backgroundColor = previousBackgroundColor

        finalGatheringSprite.position = camera.position
        finalGatheringSprite.size = gameScene.size
        
        if let uniform = CiderKitEngine.lightModelFinalGatheringShader.uniformNamed(CiderKitEngine.ShaderUniformName.albedoTexture.rawValue) {
            uniform.textureValue = albedoTexture
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
            uniform.vectorFloat3Value = ambientLightColorRGB
        }
        
        for lightIndex in 0...CiderKitEngine.ShaderUniformName.maxLightIndex {
            if let lightUniformName = CiderKitEngine.ShaderUniformName(lightIndex: lightIndex),
               let uniform = CiderKitEngine.lightModelFinalGatheringShader.uniformNamed(lightUniformName.rawValue) {
                uniform.matrixFloat3x3Value = getLightMatrix(lightIndex)
            }
        }
    }
    
    open func getLightMatrix(_ index: Int) -> matrix_float3x3 { matrix_float3x3() }
    
    public func updateSceneSize() {
        if let scene {
            scene.size = getBestMatchingSceneSize(CGSize(width: preferredSceneWidth, height: preferredSceneHeight))
        }
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
