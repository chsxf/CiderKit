import SpriteKit

public enum AssetInstanceErrors: Error {
    
    case duplicateUUID
    case unknownUUID
    
}

open class AssetInstance : TransformAssetElementInstance {
    
    public let placement: AssetPlacement
    public let assetDescription: AssetDescription
    
    public let worldPosition: SIMD3<Float>
    
    public var currentAnimationName: String? = nil {
        didSet {
            updateAll(applyDefaults: true)
        }
    }
    
    public var currentFrame: UInt = 0 {
        didSet {
            updateAll(applyDefaults: false)
        }
    }
    
    public override var absoluteOffset: SIMD3<Float> { parent?.absoluteOffset ?? (worldPosition + currentOffset) }

    private var elementInstancesByUUID: [UUID: TransformAssetElementInstance] = [:]
    private var referenceElementInstancesByUUID: [UUID: ReferenceAssetElementInstance] = [:]
    
    public subscript(element: TransformAssetElement) -> TransformAssetElementInstance? { elementInstancesByUUID[element.uuid] }
    
    public convenience init(assetDescription: AssetDescription, at worldPosition: SIMD3<Float> = SIMD3(), offsetNodeByWorldPosition: Bool = true) {
        self.init(placement: AssetPlacement(assetLocator: assetDescription.locator), at: worldPosition, offsetNodeByWorldPosition: offsetNodeByWorldPosition)!
    }
    
    public init?(placement: AssetPlacement, at worldPosition: SIMD3<Float>, offsetNodeByWorldPosition: Bool = true) {
        guard let assetDescription = placement.assetLocator.assetDescription else { return nil }
        
        self.placement = placement
        self.assetDescription = assetDescription
        
        self.worldPosition = worldPosition
        
        super.init(element: assetDescription.rootElement)
        
        createNode(at: worldPosition)
        if offsetNodeByWorldPosition {
            node!.position = node!.position + MapNode.computeNodePosition(with: worldPosition)
        }
        node!.zPosition = 1
        
        elementInstancesByUUID[assetDescription.rootElement.uuid] = self
        
        let newWorldPosition = worldPosition + assetDescription.rootElement.offset
        for child in assetDescription.rootElement.children {
            try! instantiateElement(element: child, parent: self, at: newWorldPosition)
        }
    }
    
    private func instantiateElement(element: TransformAssetElement, parent: TransformAssetElementInstance, at worldPosition: SIMD3<Float>) throws {
        guard elementInstancesByUUID[element.uuid] == nil else { throw AssetInstanceErrors.duplicateUUID }
        
        let elementInstance = element.instantiate()
        elementInstancesByUUID[element.uuid] = elementInstance
        if let referenceElementInstance = elementInstance as? ReferenceAssetElementInstance {
            referenceElementInstancesByUUID[element.uuid] = referenceElementInstance
        }
        parent.addChild(elementInstance)
        
        elementInstance.createNode(at: worldPosition)
        
        let newWorldPosition = worldPosition + element.offset
        for child in element.children {
            try instantiateElement(element: child, parent: elementInstance, at: newWorldPosition)
        }
    }
    
    public func instantiateElement(element: TransformAssetElement) throws {
        guard
            let parentElement = element.parent,
            let parentElementInstance = elementInstancesByUUID[parentElement.uuid]
        else {
            throw AssetInstanceErrors.unknownUUID
        }
        
        try instantiateElement(element: element, parent: parentElementInstance, at: parentElementInstance.absoluteOffset)
    }
    
    public func remove(element: TransformAssetElement) {
        self[element]?.removeFromParent()
    }
    
    public func remove(elementInstance: TransformAssetElementInstance) {
        elementInstancesByUUID[elementInstance.element.uuid] = nil
        referenceElementInstancesByUUID[elementInstance.element.uuid] = nil
    }
    
    @discardableResult
    public func playSKAction(_ action: SKAction, on element: TransformAssetElement) -> Bool {
        if let elementInstance = elementInstancesByUUID[element.uuid] {
            elementInstance.node?.run(action)
            return true
        }
        
        for (_, elementInstance) in referenceElementInstancesByUUID {
            if elementInstance.referencedAssetInstance?.playSKAction(action, on: element) ?? false {
                return true
            }
        }
        
        return false
    }
    
    public func killAllSKActions() {
        for (_, instance) in elementInstancesByUUID {
            instance.node?.removeAllActions()
        }
        
        for (_, elementInstace) in referenceElementInstancesByUUID {
            elementInstace.referencedAssetInstance?.killAllSKActions()
        }
    }
    
    public final func applyAllDefaults() {
        for (_, instance) in elementInstancesByUUID {
            instance.applyDefaults()
        }
    }
    
    public final func applyDefaults(for element: TransformAssetElement) {
        elementInstancesByUUID[element.uuid]?.applyDefaults()
    }
    
    public func updateAll(applyDefaults: Bool) {
        if applyDefaults {
            self.applyAllDefaults()
        }
        
        guard
            let currentAnimationName,
            let currentAnimation = assetDescription.animations[currentAnimationName]
        else { return }
        
        for elementUUID in currentAnimation.referenceElementUUIDs {
            if let instance = elementInstancesByUUID[elementUUID] {
                let animationSnapshot = assetDescription.getAnimationSnapshot(for: elementUUID, in: currentAnimationName, at: currentFrame)
                instance.update(animationSnapshot: animationSnapshot)
            }
        }
        
        for (_, elementInstance) in referenceElementInstancesByUUID {
            elementInstance.referencedAssetInstance?.currentFrame = currentFrame
        }
    }
    
    public func updateElement(_ element: TransformAssetElement) {
        guard let instance = elementInstancesByUUID[element.uuid] else { return }
        
        let animationSnapshot = assetDescription.getAnimationSnapshot(for: element.uuid, in: currentAnimationName, at: currentFrame)
        instance.update(animationSnapshot: animationSnapshot)
    }
    
    public func getSKActionsByElement(in animationName: String, with expectedDuration: TimeInterval? = nil) -> [TransformAssetElement:SKAction]? {
        guard let animationData = assetDescription.animations[animationName] else { return nil }

        var maxTrackDuration: TimeInterval = 0
        var elements = Set<TransformAssetElement>()
        for (identifier, track) in animationData.animationTracks {
            if track.hasAnyKey {
                elements.insert(assetDescription.getElement(uuid: identifier.elementUUID)!)
                if track.duration > maxTrackDuration {
                    maxTrackDuration = track.duration
                }
            }
        }
        
        let expectedDurationForActions = expectedDuration ?? maxTrackDuration
        var result = [TransformAssetElement:SKAction]()
        for element in elements {
            if let elementActions = getSKAction(for: element, in: animationName, with: expectedDurationForActions) {
                result[element] = elementActions
            }
        }
        
        for (_, elementInstance) in referenceElementInstancesByUUID {
            if let actionsForElementInstance = elementInstance.getSKActionsByElement(with: expectedDurationForActions) {
                result.merge(actionsForElementInstance) { $1 }
            }
        }
        
        return result.isEmpty ? nil : result
    }
    
    public func getSKAction(for element: TransformAssetElement, in animationName: String, with expectedDuration: TimeInterval) -> SKAction? {
        guard
            let animation = assetDescription.animations[animationName],
            let elementInstance = self[element]
        else { return nil }

        var combinedTracks = [AssetAnimationTrackType: AssetAnimationTrack]()
                
        var actions = [SKAction]()
        for (identifier, track) in animation.animationTracks {
            if identifier.elementUUID == element.uuid {
                if element.combinedTrackTypes.contains(identifier.trackType) {
                    combinedTracks[identifier.trackType] = track
                }
                else {
                    if let trackAction = track.toSKAction(with: expectedDuration, for: elementInstance) {
                        actions.append(trackAction)
                    }
                }
            }
        }
        
        if !combinedTracks.isEmpty {
            actions.append(contentsOf: elementInstance.buildSKActions(with: combinedTracks, expectedDuration: expectedDuration))
        }
        
        return actions.isEmpty ? nil : SKAction.group(actions)
    }
    
}
