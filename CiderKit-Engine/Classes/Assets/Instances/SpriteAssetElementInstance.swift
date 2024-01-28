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
            let position = spriteNode?.attributeValues[CiderKitEngine.ShaderAttributeName.position.rawValue]?.vectorFloat3Value,
            let size = spriteNode?.attributeValues[CiderKitEngine.ShaderAttributeName.size.rawValue]?.vectorFloat3Value
        else {
            return nil
        }
        
        return AssetBoundingBox(min: position, size: size)
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
        
        let rtVolumeSize = currentVolumeSize * SIMD3(1, 1, 0.25)
        spriteNode.attributeValues = [
            CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: worldPosition + currentOffset + currentVolumeOffset - rtVolumeSize * SIMD3(0.5, 0.5, 0)),
            CiderKitEngine.ShaderAttributeName.size.rawValue: SKAttributeValue(vectorFloat3: rtVolumeSize)
        ]
    }
    
    public override func applyDefaults() {
        guard let spriteNode else { return }
        
        currentVolumeOffset = spriteElement.volumeOffset
        currentVolumeSize = spriteElement.volumeSize
        
        currentSpriteLocator = spriteElement.spriteLocator
        updateSprite(spriteNode, spriteLocator: currentSpriteLocator)
        
        currentAnchorPoint = spriteElement.anchorPoint
        spriteNode.anchorPoint = currentAnchorPoint
        
        currentColor = spriteElement.color
        spriteNode.color = SKColorFromCGColor(currentColor)
        
        currentColorBlendFactor = spriteElement.colorBlend
        spriteNode.colorBlendFactor = CGFloat(currentColorBlendFactor)
        
        super.applyDefaults()
    }
    
    public override func update(animationSnapshot: AssetElementAnimationSnapshot? = nil) {
        guard
            let spriteNode,
            let snapshot = animationSnapshot ?? getAnimationSnapshot()
        else { return }
        
        if let spriteLocatorDescription: String = snapshot.get(trackType: .sprite) {
            currentSpriteLocator = SpriteLocator(description: spriteLocatorDescription)
        }
        else {
            currentSpriteLocator = nil
        }
        updateSprite(spriteNode, spriteLocator: currentSpriteLocator)
        
        let xAnchorPoint: Float = snapshot.get(trackType: .xAnchorPoint)
        let yAnchorPoint: Float = snapshot.get(trackType: .yAnchorPoint)
        currentAnchorPoint = CGPoint(x: CGFloat(xAnchorPoint), y: CGFloat(yAnchorPoint))
        spriteNode.anchorPoint = currentAnchorPoint
        
        currentColor = snapshot.get(trackType: .color)
        spriteNode.color = SKColorFromCGColor(currentColor)
        
        currentColorBlendFactor = snapshot.get(trackType: .colorBlendFactor)
        spriteNode.colorBlendFactor = CGFloat(currentColorBlendFactor)
        
        currentVolumeOffset = SIMD3<Float>(snapshot.get(trackType: .xVolumeOffset), snapshot.get(trackType: .yVolumeOffset), snapshot.get(trackType: .zVolumeOffset))
        currentVolumeSize = SIMD3<Float>(snapshot.get(trackType: .xVolumeSize), snapshot.get(trackType: .yVolumeSize), snapshot.get(trackType: .zVolumeSize))
        
        super.update(animationSnapshot: snapshot)
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
    
    public override func updateHierarchyDependentProperties() {
        if let spriteNode {
            let rtVolumeSize = currentVolumeSize * SIMD3(1, 1, 0.25)
            spriteNode.attributeValues = [
                CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: absoluteOffset + currentVolumeOffset - rtVolumeSize * SIMD3(0.5, 0.5, 0)),
                CiderKitEngine.ShaderAttributeName.size.rawValue: SKAttributeValue(vectorFloat3: rtVolumeSize)
            ]
        }
        
        super.updateHierarchyDependentProperties()
    }
    
    public override func buildSKActions(for track: AssetAnimationTrack, from key1: AssetAnimationKey, to key2: AssetAnimationKey, duration: TimeInterval) -> [SKAction]? {
        let adjustedDuration = key1 === track.firstKey ? duration : (duration - AssetAnimationTrack.frameTime)
        let timeBetweenKeys = key2.time - key1.time
        let partialTimeScaling: Float? = duration < timeBetweenKeys ? Float(duration / timeBetweenKeys) : nil
        
        switch track.type {
        case .color:
            let endColor = key2.colorValue!
            if key1.maintainValue {
                guard partialTimeScaling == nil else { return nil }
                return [
                    SKAction.wait(forDuration: adjustedDuration),
                    SKAction.customAction(withDuration: AssetAnimationTrack.frameTime) { _, _ in
                        self.currentColor = endColor
                        if let spriteNode = self.spriteNode {
                            spriteNode.color = SKColorFromCGColor(self.currentColor)
                        }
                    }
                ]
            }
            else {
                let startColor = key1.colorValue!
                let action = SKAction.customAction(withDuration: duration) { _, elapsedTime in
                    let ratio = Float(elapsedTime / timeBetweenKeys)
                    self.currentColor = CGColor.interpolateRGB(from: startColor, to: endColor, t: ratio)!
                    
                    if let spriteNode = self.spriteNode {
                        spriteNode.color = SKColorFromCGColor(self.currentColor)
                    }
                }
                action.setupTimingFunction(key1.timingInterpolation, partialTimeScaling: partialTimeScaling)
                return [ action ]
            }

        case .colorBlendFactor:
            if key1.maintainValue {
                guard partialTimeScaling == nil else { return nil }
                return [
                    SKAction.wait(forDuration: adjustedDuration),
                    SKAction.customAction(withDuration: AssetAnimationTrack.frameTime) { _, _ in
                        self.currentColorBlendFactor = key2.floatValue!
                        if let spriteNode = self.spriteNode {
                            spriteNode.colorBlendFactor = CGFloat(self.currentColorBlendFactor)
                        }
                    }
                ]
            }
            else {
                let action = SKAction.customAction(withDuration: duration) { _, elapsedTime in
                    let ratio = Float(elapsedTime / timeBetweenKeys)
                    self.currentColorBlendFactor = AssetAnimationKey.getInterpolatedValue(ratio: ratio, from: key1, to: key2) as! Float
                    if let spriteNode = self.spriteNode {
                        spriteNode.colorBlendFactor = CGFloat(self.currentColorBlendFactor)
                    }
                }
                action.setupTimingFunction(key1.timingInterpolation, partialTimeScaling: partialTimeScaling)
                return [ action ]
            }

        case .sprite:
            guard partialTimeScaling == nil else { return nil }
            
            var sequence = [SKAction]()
            sequence.append(SKAction.wait(forDuration: adjustedDuration))
            if let spriteLocator = SpriteLocator(description: key2.stringValue!) {
                sequence.append(SKAction.run {
                    if let spriteNode = self.spriteNode {
                        spriteNode.alpha = 1
                        spriteNode.texture = Atlases[spriteLocator]!
                    }
                })
            }
            else {
                sequence.append(SKAction.run {
                    if let spriteNode = self.spriteNode {
                        spriteNode.alpha = 0
                        spriteNode.texture = CiderKitEngine.clearTexture
                    }
                })
            }
            return sequence
            
        default:
            return nil
        }
    }
    
    public override func buildSKActions(with combinedTracks: [AssetAnimationTrackType : AssetAnimationTrack], expectedDuration: TimeInterval) -> [SKAction] {
        var actions = super.buildSKActions(with: combinedTracks, expectedDuration: expectedDuration)
        
        let xAnchorPoint = combinedTracks[.xAnchorPoint]
        let yAnchorPoint = combinedTracks[.yAnchorPoint]
        if xAnchorPoint != nil || yAnchorPoint != nil {
            actions.append(SKAction.customAction(withDuration: expectedDuration) { _, elapsedTime in
                guard let spriteNode = self.spriteNode else { return }
                
                let frame = UInt((elapsedTime / AssetAnimationTrack.frameTime).rounded(.towardZero))
                
                self.currentAnchorPoint.x = (xAnchorPoint?.getValue(at: frame) ?? self.currentAnchorPoint.x) as! CGFloat
                self.currentAnchorPoint.y = (yAnchorPoint?.getValue(at: frame) ?? self.currentAnchorPoint.y) as! CGFloat
                
                spriteNode.anchorPoint = self.currentAnchorPoint
            })
        }

        let xVolumeOffset = combinedTracks[.xVolumeOffset]
        let yVolumeOffset = combinedTracks[.yVolumeOffset]
        let zVolumeOffset = combinedTracks[.zVolumeOffset]
        let xVolumeSize = combinedTracks[.xVolumeSize]
        let yVolumeSize = combinedTracks[.yVolumeSize]
        let zVolumeSize = combinedTracks[.zVolumeSize]
        if xVolumeOffset != nil || yVolumeOffset != nil || zVolumeOffset != nil || xVolumeSize != nil || yVolumeSize != nil || zVolumeSize != nil {
            actions.append(SKAction.customAction(withDuration: expectedDuration) { _, elapsedTime in
                let frame = UInt((elapsedTime / AssetAnimationTrack.frameTime).rounded(.towardZero))
                
                self.currentVolumeOffset = SIMD3(
                    (xVolumeOffset?.getValue(at: frame) ?? self.currentVolumeOffset.x) as! Float,
                    (yVolumeOffset?.getValue(at: frame) ?? self.currentVolumeOffset.y) as! Float,
                    (zVolumeOffset?.getValue(at: frame) ?? self.currentVolumeOffset.z) as! Float
                )
                
                self.currentVolumeSize = SIMD3(
                    (xVolumeSize?.getValue(at: frame) ?? self.currentVolumeSize.x) as! Float,
                    (yVolumeSize?.getValue(at: frame) ?? self.currentVolumeSize.y) as! Float,
                    ((zVolumeSize?.getValue(at: frame) ?? self.currentVolumeSize.z) as! Float) * 0.25
                )
                
                self.updateHierarchyDependentProperties()
            })
        }
        
        return actions
    }
    
}
