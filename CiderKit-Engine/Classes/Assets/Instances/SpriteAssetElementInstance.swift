import SpriteKit

open class SpriteAssetElementInstance: TransformAssetElementInstance {
    
    public let spriteElement: SpriteAssetElement
    
    private var spriteNode: SKSpriteNode? = nil
    
    public var currentVolumeOffset: OverridableValue<SIMD3<Float>>
    public var currentVolumeSize: OverridableValue<SIMD3<Float>>

    public var currentSpriteLocator: OverridableValue<SpriteLocator?>
    public var currentAnchorPoint: OverridableValue<CGPoint>

    public var currentColor: OverridableValue<CGColor>
    public var currentColorBlendFactor: OverridableValue<Float>

    open override var selfBoundingBox: AssetBoundingBox? {
        guard
            let position = spriteNode?.attributeValues[CiderKitEngine.ShaderAttributeName.position.rawValue]?.vectorFloat3Value,
            let sizeAndFlip = spriteNode?.attributeValues[CiderKitEngine.ShaderAttributeName.sizeAndFlip.rawValue]?.vectorFloat4Value
        else {
            return nil
        }
        
        return AssetBoundingBox(min: position, size: SIMD3(sizeAndFlip))
    }
    
    public init(element: SpriteAssetElement) {
        spriteElement = element
        
        currentVolumeOffset = OverridableValue(element.volumeOffset)
        currentVolumeSize = OverridableValue(element.volumeSize)

        currentSpriteLocator = OverridableValue(element.spriteLocator)
        currentAnchorPoint = OverridableValue(element.anchorPoint)

        currentColor = OverridableValue(element.color)
        currentColorBlendFactor = OverridableValue(element.colorBlend)

        super.init(element: element)
    }
    
    public override func createNode(baseNode: SKNode? = nil, at worldPosition: SIMD3<Float>) {
        let spriteNode = SKSpriteNode(texture: nil)
        self.spriteNode = spriteNode
        
        super.createNode(baseNode: spriteNode, at: worldPosition)
        
        updateSprite(spriteNode, spriteLocator: currentSpriteLocator.currentValue)
        spriteNode.anchorPoint = currentAnchorPoint.currentValue

        spriteNode.color = SKColorFromCGColor(currentColor.currentValue)
        spriteNode.colorBlendFactor = CGFloat(currentColorBlendFactor.currentValue)

        var additionalOffset = currentVolumeOffset.currentValue - currentVolumeSize.currentValue * SIMD3(0.5, 0.5, 0)
        var adjustedVolumeSize = currentVolumeSize.currentValue
        var horizontallyFlippedFlag: Float = 0
        if horizontallyFlippedByAncestorOrSelf {
            additionalOffset = Self.horizontallyFlipOffset(additionalOffset)
            adjustedVolumeSize = Self.horizontallyFlipOffset(adjustedVolumeSize)
            horizontallyFlippedFlag = 1
        }
        
        spriteNode.attributeValues = [
            CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: worldPosition + adjustedCurrentOffset + additionalOffset),
            CiderKitEngine.ShaderAttributeName.sizeAndFlip.rawValue: SKAttributeValue(vectorFloat4: SIMD4(adjustedVolumeSize, horizontallyFlippedFlag))
        ]
    }
    
    public override func applyDefaults() {
        guard let spriteNode else { return }
        
        currentVolumeOffset.baseValue = spriteElement.volumeOffset
        currentVolumeSize.baseValue = spriteElement.volumeSize

        currentSpriteLocator.baseValue = spriteElement.spriteLocator
        updateSprite(spriteNode, spriteLocator: currentSpriteLocator.currentValue)

        currentAnchorPoint.baseValue = spriteElement.anchorPoint
        spriteNode.anchorPoint = currentAnchorPoint.currentValue

        currentColor.baseValue = spriteElement.color
        spriteNode.color = SKColorFromCGColor(currentColor.currentValue)

        currentColorBlendFactor.baseValue = spriteElement.colorBlend
        spriteNode.colorBlendFactor = CGFloat(currentColorBlendFactor.currentValue)

        super.applyDefaults()
    }
    
    public override func update(animationSnapshot: AssetElementAnimationSnapshot? = nil) {
        guard
            let spriteNode,
            let snapshot = animationSnapshot ?? getAnimationSnapshot()
        else { return }

        if let spriteLocatorDescription: String = snapshot.get(trackType: .sprite) {
            currentSpriteLocator.baseValue = SpriteLocator(description: spriteLocatorDescription)
        }
        else {
            currentSpriteLocator.baseValue = nil
        }
        updateSprite(spriteNode, spriteLocator: currentSpriteLocator.currentValue)

        let xAnchorPoint: Float = snapshot.get(trackType: .xAnchorPoint)
        let yAnchorPoint: Float = snapshot.get(trackType: .yAnchorPoint)
        currentAnchorPoint.baseValue = CGPoint(x: CGFloat(xAnchorPoint), y: CGFloat(yAnchorPoint))
        spriteNode.anchorPoint = currentAnchorPoint.currentValue

        currentColor.baseValue = snapshot.get(trackType: .color)
        spriteNode.color = SKColorFromCGColor(currentColor.currentValue)

        currentColorBlendFactor.baseValue = snapshot.get(trackType: .colorBlendFactor)
        spriteNode.colorBlendFactor = CGFloat(currentColorBlendFactor.currentValue)

        currentVolumeOffset.baseValue = SIMD3<Float>(snapshot.get(trackType: .xVolumeOffset), snapshot.get(trackType: .yVolumeOffset), snapshot.get(trackType: .zVolumeOffset))
        currentVolumeSize.baseValue = SIMD3<Float>(snapshot.get(trackType: .xVolumeSize), snapshot.get(trackType: .yVolumeSize), snapshot.get(trackType: .zVolumeSize))

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
        var additionalOffset = currentVolumeOffset.currentValue - currentVolumeSize.currentValue * SIMD3(0.5, 0.5, 0)
        var adjustedVolumeSize = currentVolumeSize.currentValue
        var horizontallyFlippedFlag: Float = 0
        if horizontallyFlippedByAncestorOrSelf {
            additionalOffset = Self.horizontallyFlipOffset(additionalOffset)
            adjustedVolumeSize = Self.horizontallyFlipOffset(adjustedVolumeSize)
            horizontallyFlippedFlag = 1
        }
        
        if let spriteNode {
            spriteNode.attributeValues = [
                CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: absoluteOffset + additionalOffset),
                CiderKitEngine.ShaderAttributeName.sizeAndFlip.rawValue: SKAttributeValue(vectorFloat4: SIMD4(adjustedVolumeSize, horizontallyFlippedFlag))
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
                        self.currentColor.baseValue = endColor
                        if let spriteNode = self.spriteNode {
                            spriteNode.color = SKColorFromCGColor(self.currentColor.currentValue)
                        }
                    }
                ]
            }
            else {
                let startColor = key1.colorValue!
                let action = SKAction.customAction(withDuration: duration) { _, elapsedTime in
                    let ratio = Float(elapsedTime / timeBetweenKeys)
                    self.currentColor.baseValue = CGColor.interpolateRGB(from: startColor, to: endColor, t: ratio)!

                    if let spriteNode = self.spriteNode {
                        spriteNode.color = SKColorFromCGColor(self.currentColor.currentValue)
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
                        self.currentColorBlendFactor.baseValue = key2.floatValue!
                        if let spriteNode = self.spriteNode {
                            spriteNode.colorBlendFactor = CGFloat(self.currentColorBlendFactor.currentValue)
                        }
                    }
                ]
            }
            else {
                let action = SKAction.customAction(withDuration: duration) { _, elapsedTime in
                    let ratio = Float(elapsedTime / timeBetweenKeys)
                    self.currentColorBlendFactor.baseValue = AssetAnimationKey.getInterpolatedValue(ratio: ratio, from: key1, to: key2) as! Float
                    if let spriteNode = self.spriteNode {
                        spriteNode.colorBlendFactor = CGFloat(self.currentColorBlendFactor.currentValue)
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
                
                self.currentAnchorPoint.baseValue = CGPoint(
                    x: (xAnchorPoint?.getValue(at: frame) ?? self.currentAnchorPoint.currentValue.x) as! CGFloat,
                    y: (yAnchorPoint?.getValue(at: frame) ?? self.currentAnchorPoint.currentValue.y) as! CGFloat
                )

                spriteNode.anchorPoint = self.currentAnchorPoint.currentValue
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
                
                self.currentVolumeOffset.baseValue = SIMD3(
                    (xVolumeOffset?.getValue(at: frame) ?? self.currentVolumeOffset.currentValue.x) as! Float,
                    (yVolumeOffset?.getValue(at: frame) ?? self.currentVolumeOffset.currentValue.y) as! Float,
                    (zVolumeOffset?.getValue(at: frame) ?? self.currentVolumeOffset.currentValue.z) as! Float
                )
                
                self.currentVolumeSize.baseValue = SIMD3(
                    (xVolumeSize?.getValue(at: frame) ?? self.currentVolumeSize.currentValue.x) as! Float,
                    (yVolumeSize?.getValue(at: frame) ?? self.currentVolumeSize.currentValue.y) as! Float,
                    ((zVolumeSize?.getValue(at: frame) ?? self.currentVolumeSize.currentValue.z) as! Float)
                )
                
                self.updateHierarchyDependentProperties()
            })
        }
        
        return actions
    }

    public override func resetAllOverriddenValues(options: ResetOverriddenValuesOptions = [.applyToChildren, .updateImmediately]) {
        currentVolumeOffset.overriddenValue = nil
        currentVolumeSize.overriddenValue = nil
        currentSpriteLocator.overriddenValue = nil
        currentAnchorPoint.overriddenValue = nil
        currentColor.overriddenValue = nil
        currentColorBlendFactor.overriddenValue = nil

        super.resetAllOverriddenValues(options: options)
    }

}
