import SpriteKit

open class TransformAssetElementInstance {
    
    public var assetInstance: AssetInstance? { (self as? AssetInstance) ?? parent?.assetInstance }
    
    public let element: TransformAssetElement
    public private(set) weak var parent: TransformAssetElementInstance? = nil
    
    public private(set) var children: [TransformAssetElementInstance] = []
    
    public private(set) var node: SKNode? = nil
    
    public var absoluteOffset: SIMD3<Float> { (parent?.absoluteOffset ?? SIMD3()) + currentOffset }
    
    public private(set) var currentVisibility: Bool
    public private(set) var currentOffset: SIMD3<Float>
    
    public final var boundingBox: AssetBoundingBox? {
        var bb: AssetBoundingBox? = selfBoundingBox
        for child in children {
            if let childBB = child.boundingBox {
                bb = bb?.encapsulating(other: childBB) ?? childBB
            }
        }
        return bb
    }
    
    open var selfBoundingBox: AssetBoundingBox? { nil }
    
    public init(element: TransformAssetElement) {
        self.element = element
        currentVisibility = element.visible
        currentOffset = element.offset
    }
    
    public final func addChild(_ child: TransformAssetElementInstance) {
        children.append(child)
        child.parent = self
    }
    
    public final func removeFromParent() {
        assetInstance?.remove(elementInstance: self)
        parent?.children.removeAll(where: { $0 === self })
        node?.removeFromParent()
    }
    
    open func createNode(baseNode: SKNode? = nil, at worldPosition: SIMD3<Float>) {
        let node = baseNode ?? SKNode()
        self.node = node
        node.name = element.name
        node.isHidden = !currentVisibility
        node.position = MapNode.computeNodePosition(with: currentOffset)
        
        if let parentNode = parent?.node {
            parentNode.addChild(node)
        }
    }

    public func applyDefaults() {
        guard let node else { return }
        
        currentVisibility = element.visible
        node.isHidden = !currentVisibility
        
        currentOffset = element.offset
        node.position = MapNode.computeNodePosition(with: currentOffset)
        
        updateHierarchyDependentProperties()
    }
    
    public final func getAnimationSnapshot() -> AssetElementAnimationSnapshot? {
        assetInstance?.assetDescription.getAnimationSnapshot(for: element.uuid, in: assetInstance?.currentAnimationName, at: assetInstance?.currentFrame ?? 0)
    }
    
    public func update(animationSnapshot: AssetElementAnimationSnapshot? = nil) {
        guard
            let node,
            let snapshot = animationSnapshot ?? getAnimationSnapshot()
        else { return }
        
        currentVisibility = snapshot.get(trackType: .visibility)
        node.isHidden = !currentVisibility

        currentOffset = SIMD3(snapshot.get(trackType: .xOffset), snapshot.get(trackType: .yOffset), snapshot.get(trackType: .zOffset))
        node.position = MapNode.computeNodePosition(with: currentOffset)
        
        updateHierarchyDependentProperties()
    }
    
    
    public func updateHierarchyDependentProperties() {
        for child in children {
            child.updateHierarchyDependentProperties()
        }
    }
    
    public func buildSKActions(for track: AssetAnimationTrack, from key1: AssetAnimationKey, to key2: AssetAnimationKey, duration: TimeInterval) -> [SKAction]? {
        guard track.type == .visibility else { return nil }
    
        let timeBetweenKeys = key2.time - key1.time
        guard duration >= timeBetweenKeys else { return nil }
                
        return [
            SKAction.wait(forDuration: duration),
            SKAction.run({
                self.currentVisibility = key2.boolValue!
                self.node?.isHidden = !self.currentVisibility
            })
        ]
    }
    
    public func buildSKActions(with combinedTracks: [AssetAnimationTrackType: AssetAnimationTrack], expectedDuration: TimeInterval) -> [SKAction] {
        var actions = [SKAction]()
        
        let xOffsetTrack = combinedTracks[.xOffset]
        let yOffsetTrack = combinedTracks[.yOffset]
        let zOffsetTrack = combinedTracks[.zOffset]
        if xOffsetTrack != nil || yOffsetTrack != nil || zOffsetTrack != nil {
            actions.append(SKAction.customAction(withDuration: expectedDuration) { node, elapsedTime in
                let frame = UInt((elapsedTime / AssetAnimationTrack.frameTime).rounded(.towardZero))
                
                self.currentOffset = SIMD3(
                    (xOffsetTrack?.getValue(at: frame) ?? self.currentOffset.x) as! Float,
                    (yOffsetTrack?.getValue(at: frame) ?? self.currentOffset.y) as! Float,
                    (zOffsetTrack?.getValue(at: frame) ?? self.currentOffset.z) as! Float
                )
                
                self.updateHierarchyDependentProperties()
                
                node.position = MapNode.computeNodePosition(with: self.currentOffset)
            })
        }
        
        return actions
    }
    
}
