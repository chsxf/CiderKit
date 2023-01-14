import SpriteKit

open class SpriteAssetNode: SKNode {
    
    private var nodeByElementUUID: [UUID: SKNode] = [:]
    
    private let assetDescription: SpriteAssetDescription
    
    private let shaderPosition: simd_float3
    private let shaderSize: simd_float3
    
    public let placement: SpriteAssetPlacement

    public init(placement: SpriteAssetPlacement, description: SpriteAssetDescription, at worldPosition: simd_float3) {
        self.placement = placement
        assetDescription = description

        var assetPosition = description.position
        assetPosition.z *= 0.25
        shaderPosition = worldPosition + assetPosition
        
        var assetSize = description.size
        assetSize.z *= 0.25
        shaderSize = assetSize
        
        super.init()
        
        name = description.name
        
        for element in description.rootElement.children {
            let _ = createChildElement(element: element, parentElement: nil)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createChildElement(element: SpriteAssetElement, parentElement: SpriteAssetElement?) -> SKNode {
        if let parentElement {
            let parentNode = nodeByElementUUID[parentElement.uuid]!
            return createChildElement(element: element, parentNode: parentNode)
        }
        else {
            return createChildElement(element: element, parentNode: self)
        }
    }
    
    private func createChildElement(element: SpriteAssetElement, parentNode: SKNode) -> SKNode {
        let node: SKNode
        if let spriteLocator = element.data.spriteLocator {
            let texture = Atlases[spriteLocator]!
            let spriteNode = SKSpriteNode(texture: texture)
            node = spriteNode
            
            spriteNode.color = SKColor(cgColor: element.data.color)!
            spriteNode.colorBlendFactor = CGFloat(element.data.colorBlend)
            
            let atlas = Atlases[spriteLocator.atlasKey]!
            spriteNode.shader = CiderKitEngine.instantianteUberShader(for: atlas)
            
            spriteNode.attributeValues = [
                CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: shaderPosition),
                CiderKitEngine.ShaderAttributeName.size.rawValue: SKAttributeValue(vectorFloat3: shaderSize)
            ]
        }
        else {
            node = SKNode()
        }
        node.name = element.name
        node.isHidden = !element.data.visible
        node.position = element.data.offset
        node.zRotation = CGFloat(element.data.rotation)
        node.xScale = element.data.scale.x
        node.yScale = element.data.scale.y
        parentNode.addChild(node)
        nodeByElementUUID[element.uuid] = node
        
        for child in element.children {
            let _ = createChildElement(element: child, parentNode: node)
        }
        
        return node
    }
    
}
