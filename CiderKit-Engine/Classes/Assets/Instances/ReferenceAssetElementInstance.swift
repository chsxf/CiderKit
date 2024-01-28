import SpriteKit

public final class ReferenceAssetElementInstance: TransformAssetElementInstance {
    
    public let referenceElement: ReferenceAssetElement
    
    public private(set) var referencedAssetInstance: AssetInstance? = nil
    
    private var actualAnimationStateName: String? {
        guard
            let referencedAnimationStateName = referenceElement.animationStateName,
            let referencedAssetInstance,
            referencedAssetInstance.assetDescription.animationStates[referencedAnimationStateName] != nil
        else { return nil }

        return referencedAnimationStateName
    }
    
    public init(element: ReferenceAssetElement) {
        referenceElement = element
        
        super.init(element: element)
    }
    
    public override func createNode(baseNode: SKNode? = nil, at worldPosition: SIMD3<Float>) {
        super.createNode(at: worldPosition)
        
        if let assetDescription = referenceElement.assetLocator?.assetDescription {
            instantiateReferencedAsset(in: node!, from: assetDescription)
        }
    }
    
    public override func applyDefaults() {
        super.applyDefaults()
        referencedAssetInstance?.applyAllDefaults()
    }
    
    public override func update(animationSnapshot: AssetElementAnimationSnapshot? = nil) {
        guard let node else { return }
        
        super.update(animationSnapshot: animationSnapshot)
        
        let assetDescription = referenceElement.assetLocator?.assetDescription
        if referencedAssetInstance?.assetDescription !== assetDescription {
            referencedAssetInstance?.removeFromParent()
            if assetDescription != nil {
                instantiateReferencedAsset(in: node, from: assetDescription!)
            }
        }
        
        referencedAssetInstance?.currentAnimationStateName = referenceElement.animationStateName
    }
    
    private func instantiateReferencedAsset(in node: SKNode, from assetDescription: AssetDescription) {
        let referencedAssetInstance = AssetInstance(assetDescription: assetDescription, at: absoluteOffset)
        self.referencedAssetInstance = referencedAssetInstance
        addChild(referencedAssetInstance)
        node.addChild(referencedAssetInstance.node!)
        referencedAssetInstance.currentAnimationStateName = referenceElement.animationStateName
    }
    
    public func getSKActionsByElement(with maxDuration: TimeInterval) -> [TransformAssetElement: SKAction]? {
        guard let actualAnimationStateName else { return nil }
        return referencedAssetInstance?.getSKActionsByElement(in: actualAnimationStateName, with: maxDuration)
    }
    
}
