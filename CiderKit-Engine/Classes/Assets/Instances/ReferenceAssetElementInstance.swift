import SpriteKit

public final class ReferenceAssetElementInstance: TransformAssetElementInstance {
    
    public let referenceElement: ReferenceAssetElement
    
    public private(set) var referencedAssetInstance: AssetInstance? = nil
    
    private var actualAnimationName: String? {
        guard
            let referencedAnimationName = referenceElement.animationName,
            let referencedAssetInstance,
            referencedAssetInstance.assetDescription.animations[referencedAnimationName] != nil
        else { return nil }

        return referencedAnimationName
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
        
        referencedAssetInstance?.currentAnimationName.overriddenValue = referenceElement.animationName
    }
    
    private func instantiateReferencedAsset(in node: SKNode, from assetDescription: AssetDescription) {
        let referencedAssetInstance = AssetInstance(assetDescription: assetDescription, horizontallyFlipped: false, at: absoluteOffset, offsetNodeByWorldPosition: false)
        self.referencedAssetInstance = referencedAssetInstance
        addChild(referencedAssetInstance)
        node.addChild(referencedAssetInstance.node!)
        referencedAssetInstance.currentAnimationName.overriddenValue = referenceElement.animationName
    }
    
    public func getSKActionsByElement(with maxDuration: TimeInterval) -> [TransformAssetElement: SKAction]? {
        guard let actualAnimationName else { return nil }
        return referencedAssetInstance?.getSKActionsByElement(in: actualAnimationName, with: maxDuration)
    }

    public override func resetAllOverriddenValues(options: ResetOverriddenValuesOptions = [.applyToChildren, .updateImmediately]) {
        super.resetAllOverriddenValues(options: options)

        if options.contains(.applyToNestedReferences) {
            referencedAssetInstance?.resetAllOverriddenValues(options: options)
        }
    }

}
