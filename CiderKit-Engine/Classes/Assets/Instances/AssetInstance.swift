import SpriteKit

public enum AssetInstanceErrors: Error {
    
    case duplicateUUID
    case unknownUUID
    
}

open class AssetInstance : TransformAssetElementInstance {
    
    public let placement: AssetPlacement
    public let assetDescription: AssetDescription
    
    private var instancesByElementUUID: [UUID: TransformAssetElementInstance] = [:]
    
    public convenience init(assetDescription: AssetDescription, at worldPosition: SIMD3<Float> = SIMD3()) {
        self.init(placement: AssetPlacement(assetLocator: assetDescription.locator), at: worldPosition)!
    }
    
    public init?(placement: AssetPlacement, at worldPosition: SIMD3<Float>) {
        guard let assetDescription = placement.assetLocator.assetDescription else { return nil }
        
        self.placement = placement
        self.assetDescription = assetDescription
        
        super.init(element: assetDescription.rootElement)
        
        createNode(at: worldPosition)
        node!.zPosition = 1
        
        instancesByElementUUID[assetDescription.rootElement.uuid] = self
        
        let newWorldPosition = worldPosition + assetDescription.rootElement.offset
        for child in assetDescription.rootElement.children {
            try! instantiateElement(element: child, parent: self, at: newWorldPosition)
        }
    }
    
    private func instantiateElement(element: TransformAssetElement, parent: TransformAssetElementInstance, at worldPosition: SIMD3<Float>) throws {
        guard instancesByElementUUID[element.uuid] == nil else { throw AssetInstanceErrors.duplicateUUID }
        
        let elementInstance = element.instantiate()
        instancesByElementUUID[element.uuid] = elementInstance
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
            let parentElementInstance = instancesByElementUUID[parentElement.uuid]
        else {
            throw AssetInstanceErrors.unknownUUID
        }
        
        try instantiateElement(element: element, parent: parentElementInstance, at: parentElementInstance.absoluteOffset)
    }
    
    public subscript(element: TransformAssetElement) -> TransformAssetElementInstance? { instancesByElementUUID[element.uuid] }
    
    public func playSKAction(_ action: SKAction, on element: TransformAssetElement) {
        instancesByElementUUID[element.uuid]?.node?.run(action)
    }
    
    public func killAllSKActions() {
        for (_, instance) in instancesByElementUUID {
            instance.node?.removeAllActions()
        }
    }
    
    public func updateElement(_ element: TransformAssetElement, with animationSnapshot: AssetElementAnimationSnapshot) {
        instancesByElementUUID[element.uuid]?.update(animationSnapshot: animationSnapshot)
    }
    
}
