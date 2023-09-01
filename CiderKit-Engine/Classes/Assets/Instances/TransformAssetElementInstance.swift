import SpriteKit

open class TransformAssetElementInstance {
    
    public let element: TransformAssetElement
    public private(set) weak var parent: TransformAssetElementInstance? = nil
    
    public private(set) var children: [TransformAssetElementInstance] = []
    
    public private(set) var node: SKNode? = nil
    
    public var absoluteOffset: SIMD3<Float> { (parent?.absoluteOffset ?? SIMD3()) + element.offset }
    
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
        parent?.children.removeAll(where: { $0 === self })
        node?.removeFromParent()
    }
    
    open func createNode(baseNode: SKNode? = nil, at worldPosition: SIMD3<Float>) {
        let node = baseNode ?? SKNode()
        self.node = node
        node.name = element.name
        node.isHidden = !currentVisibility
        node.position = TransformAssetElement.computeNodePosition(with: currentOffset)
        
        if let parentNode = parent?.node {
            parentNode.addChild(node)
        }
    }
    
    public func update(animationSnapshot: AssetElementAnimationSnapshot) {
        guard let node else { return }
        
        currentVisibility = animationSnapshot.get(trackType: .visibility)
        node.isHidden = !currentVisibility

        currentOffset = SIMD3(animationSnapshot.get(trackType: .xOffset), animationSnapshot.get(trackType: .yOffset), animationSnapshot.get(trackType: .zOffset))
        node.position = TransformAssetElement.computeNodePosition(with: currentOffset)
    }
    
}
