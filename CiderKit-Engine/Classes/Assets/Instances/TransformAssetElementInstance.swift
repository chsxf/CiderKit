import SpriteKit

open class TransformAssetElementInstance {
    
    public let uuid = UUID()
    
    public var assetInstance: AssetInstance? { (self as? AssetInstance) ?? parent?.assetInstance }
    
    public let element: TransformAssetElement
    public private(set) weak var parent: TransformAssetElementInstance? = nil
    
    public private(set) var children: [TransformAssetElementInstance] = []
    
    public private(set) var node: SKNode? = nil
    
    public var absoluteWorldOffset: WorldPosition { (parent?.absoluteWorldOffset ?? WorldPosition()) + adjustedCurrentWorldOffset }

    public var currentVisibility: OverridableValue<Bool>
    public var currentWorldOffset: OverridableValue<WorldPosition>

    public var adjustedCurrentWorldOffset: WorldPosition { horizontallyFlippedByAncestorOrSelf ? Self.horizontallyFlipOffset(currentWorldOffset.currentValue) : currentWorldOffset.currentValue }

    public final var horizontalFlipCountInAncestors: Int { (parent?.horizontalFlipCountInAncestors ?? 0) + (horizontallyFlippedBySelf ? 1 : 0) }
    
    public var horizontallyFlippedBySelf: Bool { element.horizontallyFlipped }
    public final var horizontallyFlippedByAncestorOrSelf: Bool { horizontalFlipCountInAncestors % 2 != 0 }
    
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
        currentVisibility = OverridableValue(element.visible)
        currentWorldOffset = OverridableValue(element.worldOffset)
    }
    
    public final func addChild(_ child: TransformAssetElementInstance) {
        children.append(child)
        child.parent = self
    }
    
    public final func removeFromParent() {
        assetInstance?.remove(elementInstance: self)
        parent?.children.removeAll { $0 === self }
        node?.removeFromParent()
    }
    
    public func applyPosition(_ node: SKNode) {
        node.position = MapNode.worldToScene(currentWorldOffset.currentValue)
    }

    open func createNode(baseNode: SKNode? = nil, atWorldPosition worldPosition: WorldPosition) {
        let node = baseNode ?? SKNode()
        self.node = node
        node.name = element.name
        node.isHidden = !currentVisibility.currentValue
        applyPosition(node)
        node.xScale = horizontallyFlippedBySelf ? -1 : 1
        
        if let parentNode = parent?.node {
            parentNode.addChild(node)
        }
    }

    public func applyDefaults() {
        guard let node else { return }
        
        currentVisibility.baseValue = element.visible
        node.isHidden = !currentVisibility.currentValue

        currentWorldOffset.baseValue = element.worldOffset
        applyPosition(node)

        node.xScale = horizontallyFlippedBySelf ? -1 : 1
        
        updateHierarchyDependentProperties()
    }
    
    public final func getAnimationSnapshot() -> AssetElementAnimationSnapshot? {
        assetInstance?.assetDescription.getAnimationSnapshot(for: element.uuid, in: assetInstance?.currentAnimationName.currentValue, at: assetInstance?.currentFrame.currentValue ?? 0)
    }
    
    public func update(animationSnapshot: AssetElementAnimationSnapshot? = nil) {
        guard
            let node,
            let snapshot = animationSnapshot ?? getAnimationSnapshot()
        else { return }
        
        currentVisibility.baseValue = snapshot.get(trackType: .visibility)
        node.isHidden = !currentVisibility.currentValue

        currentWorldOffset.baseValue = WorldPosition(snapshot.get(trackType: .xWorldOffset), snapshot.get(trackType: .yWorldOffset), snapshot.get(trackType: .zWorldOffset))
        applyPosition(node)

        node.xScale = horizontallyFlippedBySelf ? -1 : 1
        
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
                self.currentVisibility.baseValue = key2.boolValue!
                self.node?.isHidden = !self.currentVisibility.baseValue
            })
        ]
    }
    
    public func buildSKActions(with combinedTracks: [AssetAnimationTrackType: AssetAnimationTrack], expectedDuration: TimeInterval) -> [SKAction] {
        var actions = [SKAction]()
        
        let xWorldOffsetTrack = combinedTracks[.xWorldOffset]
        let yWorldOffsetTrack = combinedTracks[.yWorldOffset]
        let zWorldOffsetTrack = combinedTracks[.zWorldOffset]
        if xWorldOffsetTrack != nil || yWorldOffsetTrack != nil || zWorldOffsetTrack != nil {
            actions.append(SKAction.customAction(withDuration: expectedDuration) { node, elapsedTime in
                let frame = UInt((elapsedTime / AssetAnimationTrack.frameTime).rounded(.towardZero))
                
                self.currentWorldOffset.baseValue = WorldPosition(
                    (xWorldOffsetTrack?.getValue(at: frame) ?? self.currentWorldOffset.currentValue.x) as! Float,
                    (yWorldOffsetTrack?.getValue(at: frame) ?? self.currentWorldOffset.currentValue.y) as! Float,
                    (zWorldOffsetTrack?.getValue(at: frame) ?? self.currentWorldOffset.currentValue.z) as! Float
                )
                
                self.updateHierarchyDependentProperties()
                
                self.applyPosition(node)
            })
        }
        
        return actions
    }

    public func getElementInstances<T>(options: GetElementInstancesOptions = .directChildrenOnly) -> [T] where T : TransformAssetElementInstance {
        var elementInstances = [T]()

        if let selfAsT = self as? T {
            elementInstances.append(selfAsT)
        }

        for child in children {
            if let childAsT = child as? T {
                elementInstances.append(childAsT)
            }

            if !options.contains(.directChildrenOnly) {
                let childElementInstances: [T] = child.getElementInstances(options: options)
                elementInstances.append(contentsOf: childElementInstances)

                if options.contains(.includeNestedReferences), let referencedInstance = (child as? ReferenceAssetElementInstance)?.referencedAssetInstance {
                    let referencedElementInstances: [T] = referencedInstance.getElementInstances(options: options)
                    elementInstances.append(contentsOf: referencedElementInstances)
                }
            }
        }

        return elementInstances
    }

    public func resetAllOverriddenValues(options: ResetOverriddenValuesOptions = [.applyToChildren, .updateImmediately]) {
        currentVisibility.overriddenValue = nil
        currentWorldOffset.overriddenValue = nil

        if options.contains(.updateImmediately) {
            update()
        }

        if options.contains(.applyToChildren) {
            for child in children {
                child.resetAllOverriddenValues(options: options)
            }
        }
    }

    class func horizontallyFlipOffset(_ worldOffset: WorldPosition) -> WorldPosition {
        WorldPosition(worldOffset.y, worldOffset.x, worldOffset.z)
    }

}
