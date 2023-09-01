import SpriteKit

public final class ReferenceAssetElementInstance: TransformAssetElementInstance {
    
    public let referenceElement: ReferenceAssetElement
    
    private var referencedAssetInstance: AssetInstance? = nil
    
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
    
    public override func update(animationSnapshot: AssetElementAnimationSnapshot) {
        guard let node else { return }
        
        super.update(animationSnapshot: animationSnapshot)
        
        let assetDescription = referenceElement.assetLocator?.assetDescription
        if referencedAssetInstance?.assetDescription !== assetDescription {
            referencedAssetInstance?.removeFromParent()
            if assetDescription != nil {
                instantiateReferencedAsset(in: node, from: assetDescription!)
            }
        }
    }
    
    private func instantiateReferencedAsset(in node: SKNode, from assetDescription: AssetDescription) {
        let referencedAssetInstance = AssetInstance(assetDescription: assetDescription, at: absoluteOffset)
        self.referencedAssetInstance = referencedAssetInstance
        addChild(referencedAssetInstance)
        node.addChild(referencedAssetInstance.node!)
    }
    
}
