import SpriteKit

open class SpriteAssetElementInstance: TransformAssetElementInstance {
    
    public let spriteElement: SpriteAssetElement
    
    private var spriteNode: SKSpriteNode? = nil
    
    public private(set) var currentVolumeOffset: SIMD3<Float>
    public private(set) var currentVolumeSize: SIMD3<Float>
    
    public private(set) var currentSpriteLocator: SpriteLocator?
    public private(set) var currentAnchorPoint: CGPoint
    
    public private(set) var currentColor: CGColor
    public private(set) var currentColorBlendFactor: Float
    
    open override var selfBoundingBox: AssetBoundingBox? {
        guard
            let min = spriteNode?.attributeValues[CiderKitEngine.ShaderAttributeName.position.rawValue]?.vectorFloat3Value,
            let size = spriteNode?.attributeValues[CiderKitEngine.ShaderAttributeName.size.rawValue]?.vectorFloat3Value
        else {
            return nil
        }
        
        return AssetBoundingBox(min: min, size: size)
    }
    
    public init(element: SpriteAssetElement) {
        spriteElement = element
        
        currentVolumeOffset = element.volumeOffset
        currentVolumeSize = element.volumeSize
        
        currentSpriteLocator = element.spriteLocator
        currentAnchorPoint = element.anchorPoint
        
        currentColor = element.color
        currentColorBlendFactor = element.colorBlend
        
        super.init(element: element)
    }
    
    public override func createNode(baseNode: SKNode? = nil, at worldPosition: SIMD3<Float>) {
        let spriteNode = SKSpriteNode(texture: nil)
        self.spriteNode = spriteNode
        
        super.createNode(baseNode: spriteNode, at: worldPosition)
        
        updateSprite(spriteNode, spriteLocator: currentSpriteLocator)
        spriteNode.anchorPoint = currentAnchorPoint
        
        spriteNode.color = SKColorFromCGColor(currentColor)
        spriteNode.colorBlendFactor = CGFloat(currentColorBlendFactor)
        
        spriteNode.attributeValues = [
            CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: worldPosition + currentOffset + currentVolumeOffset),
            CiderKitEngine.ShaderAttributeName.size.rawValue: SKAttributeValue(vectorFloat3: currentVolumeSize * vector_float3(1, 1, 0.25))
        ]
    }
    
    public override func update(animationSnapshot: AssetElementAnimationSnapshot) {
        guard let spriteNode else { return }
        
        if animationSnapshot.animatedValues[.sprite] != nil {
            let spriteLocatorDescription: String = animationSnapshot.get(trackType: .sprite)
            currentSpriteLocator = SpriteLocator(description: spriteLocatorDescription)
        }
        updateSprite(spriteNode, spriteLocator: currentSpriteLocator)
        
        let xAnchorPoint: Float = animationSnapshot.get(trackType: .xAnchorPoint)
        let yAnchorPoint: Float = animationSnapshot.get(trackType: .yAnchorPoint)
        currentAnchorPoint = CGPoint(x: CGFloat(xAnchorPoint), y: CGFloat(yAnchorPoint))
        spriteNode.anchorPoint = currentAnchorPoint
        
        currentColor = animationSnapshot.get(trackType: .color)
        spriteNode.color = SKColorFromCGColor(currentColor)
        
        currentColorBlendFactor = animationSnapshot.get(trackType: .colorBlendFactor)
        spriteNode.colorBlendFactor = CGFloat(currentColorBlendFactor)
        
        currentVolumeOffset = SIMD3<Float>(animationSnapshot.get(trackType: .xVolumeOffset), animationSnapshot.get(trackType: .yVolumeOffset), animationSnapshot.get(trackType: .zVolumeOffset))
        
        currentVolumeSize = SIMD3<Float>(animationSnapshot.get(trackType: .xVolumeSize), animationSnapshot.get(trackType: .yVolumeSize), animationSnapshot.get(trackType: .zVolumeSize))
        
        spriteNode.attributeValues = [
            CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: absoluteOffset + currentVolumeOffset),
            CiderKitEngine.ShaderAttributeName.size.rawValue: SKAttributeValue(vectorFloat3: currentVolumeSize * vector_float3(1, 1, 0.25))
        ]
        
        super.update(animationSnapshot: animationSnapshot)
    }
    
    private func updateSprite(_ spriteNode: SKSpriteNode, spriteLocator: SpriteLocator?) {
        if let spriteLocator {
            let texture = Atlases[spriteLocator]!
            spriteNode.texture = texture
            spriteNode.size = texture.size()
            
            let atlas = Atlases[spriteLocator.atlasKey]!
            spriteNode.shader = CiderKitEngine.instantianteUberShader(for: atlas)
        }
        else {
            spriteNode.texture = CiderKitEngine.clearTexture
            spriteNode.shader = nil
        }
    }
    
}
