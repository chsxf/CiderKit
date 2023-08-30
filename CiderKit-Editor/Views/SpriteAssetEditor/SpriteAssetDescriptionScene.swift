import SpriteKit
import CiderKit_Engine

class SpriteAssetDescriptionScene: SKScene {
    
    private static let defaultSize: CGFloat = 320
    
    private static var gridTexture: SKTexture? = nil
    
    private let backBoundingBoxShape: SKShapeNode
    private let frontBoundingBoxShape: SKShapeNode
    private let gridRoot: SKNode
    private let elementsRoot: SKNode
    
    private var nodeByElement: [SpriteAssetElement: SKNode] = [:]
    
    override init() {
        backBoundingBoxShape = SKShapeNode()
        backBoundingBoxShape.strokeColor = .purple
        frontBoundingBoxShape = SKShapeNode()
        frontBoundingBoxShape.strokeColor = .purple
        
        gridRoot = SKNode()
        elementsRoot = SKNode()

        super.init(size: CGSize(width: 320, height: 320))
        
        scaleMode = .aspectFill
        
        if Self.gridTexture == nil {
            Self.gridTexture = Atlases["grid"]!["grid_tile_Base"]!
        }
        
        addChild(gridRoot)
        setFootprintGrid(vector_uint2(1, 1))
        
        backBoundingBoxShape.position = CGPoint(x: 0, y: Self.gridTexture!.size().height / 2)
        addChild(backBoundingBoxShape)
        addChild(elementsRoot)
        frontBoundingBoxShape.position = backBoundingBoxShape.position
        addChild(frontBoundingBoxShape)
        
        let camera = SKCameraNode()
        self.camera = camera
        addChild(camera)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setZoomFactor(_ zoomFactor: Int) {
        let newDimension: CGFloat
        switch zoomFactor {
        case 0:
            newDimension = Self.defaultSize * 2
        case -1:
            newDimension = Self.defaultSize * 4
        default:
            newDimension = Self.defaultSize / CGFloat(zoomFactor)
        }
        size = CGSize(width: newDimension, height: newDimension)
    }
    
    func playSKAction(_ action: SKAction, on element: SpriteAssetElement) {
        nodeByElement[element]?.run(action)
    }
    
    func killAllSKActions() {
        for (_, node) in nodeByElement {
            node.removeAllActions()
        }
    }
    
    public func setBoundingBox(position: vector_float3, size: vector_float3) {
        let xVector = vector_float2(Float(MapNode.halfWidth), Float(-MapNode.halfHeight))
        let yVector = vector_float2(Float(-MapNode.halfWidth), Float(-MapNode.halfHeight))
        let zVector = vector_float2(0, Float(MapNode.elevationHeight))
        
        let origin = xVector * position.x + yVector * position.y + zVector * position.z
        
        let topBack = origin + zVector * size.z
        let topLeft = topBack + yVector * size.y
        let topRight = topBack + xVector * size.x
        let topFront = topLeft + xVector * size.x
        let bottomLeft = origin + yVector * size.y
        let bottomFront = bottomLeft + xVector * size.x
        let bottomRight = origin + xVector * size.x
        
        let pathBack = CGMutablePath()
        pathBack.move(to: bottomLeft)
        pathBack.addLine(to: origin)
        pathBack.addLine(to: topBack)
        pathBack.addLine(to: topLeft)
        pathBack.addLine(to: bottomLeft)
        pathBack.addLine(to: bottomFront)
        pathBack.addLine(to: bottomRight)
        pathBack.addLine(to: topRight)
        pathBack.addLine(to: topBack)
        pathBack.move(to: origin)
        pathBack.addLine(to: bottomRight)
        backBoundingBoxShape.path = pathBack
        
        let pathFront = CGMutablePath()
        pathFront.move(to: topLeft)
        pathFront.addLine(to: topFront)
        pathFront.addLine(to: bottomFront)
        pathFront.move(to: topFront)
        pathFront.addLine(to: topRight)
        frontBoundingBoxShape.path = pathFront
    }
    
    public func setFootprintGrid(_ footprint: vector_uint2) {
        print(footprint)
        
        guard let gridTexture = Self.gridTexture else { return }
        
        let gridRootChildren = gridRoot.children
        gridRootChildren.forEach { $0.removeFromParent() }
        
        
        
        for x in -Int(footprint.x - 1)...0 {
            for y in 0..<Int(footprint.y) {
                let sprite = SKSpriteNode(texture: gridTexture)
                sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                sprite.position = CGPoint(
                    x: MapNode.halfWidth * (x + y),
                    y: MapNode.halfHeight * (y - x)
                )
                gridRoot.addChild(sprite)
            }
        }
    }
    
    public func createChildElementNode(element: SpriteAssetElement, parentElement: SpriteAssetElement?) -> SKNode {
        if let parentElement {
            let parentNode = nodeByElement[parentElement]!
            return createChildElementNode(element: element, parentNode: parentNode)
        }
        else {
            return createChildElementNode(element: element, parentNode: elementsRoot)
        }
    }
    
    private func createChildElementNode(element: SpriteAssetElement, parentNode: SKNode?) -> SKNode {
        let node: SKNode
        if let spriteLocator = element.data.spriteLocator {
            let texture = Atlases[spriteLocator]!
            let spriteNode = SKSpriteNode(texture: texture)
            node = spriteNode
            
            spriteNode.color = SKColorFromCGColor(element.data.color)
            spriteNode.colorBlendFactor = CGFloat(element.data.colorBlend)
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
        parentNode?.addChild(node)
        nodeByElement[element] = node
        
        for child in element.children {
            let _ = createChildElementNode(element: child, parentNode: node)
        }
        
        return node
    }
    
    public func removeNodes(from element: SpriteAssetElement) {
        let elementNode = nodeByElement[element]!
        elementNode.removeFromParent()
        removeNodeAndChildrenFromReferenceDictionary(topElement: element)
    }
    
    private func removeNodeAndChildrenFromReferenceDictionary(topElement: SpriteAssetElement) {
        nodeByElement.removeValue(forKey: topElement)
        for child in topElement.children {
            removeNodeAndChildrenFromReferenceDictionary(topElement: child)
        }
    }
    
    public func setNodeVisibility(from element: SpriteAssetElement, visible: Bool) {
        let node = nodeByElement[element]!
        node.isHidden = !visible
    }
    
    public func setNodeXPosition(from element: SpriteAssetElement, x: CGFloat) {
        let node = nodeByElement[element]!
        node.position.x = x
    }
    
    public func setNodeYPosition(from element: SpriteAssetElement, y: CGFloat) {
        let node = nodeByElement[element]!
        node.position.y = y
    }
    
    public func setNodeRotation(from element: SpriteAssetElement, rotationDegrees rotation: Float) {
        let degrees = Measurement(value: Double(rotation), unit: UnitAngle.degrees)
        let radians = degrees.converted(to: UnitAngle.radians)
        let node = nodeByElement[element]!
        node.zRotation = CGFloat(radians.value)
    }
    
    public func setNodeXScale(from element: SpriteAssetElement, scale: CGFloat) {
        let node = nodeByElement[element]!
        node.xScale = scale
    }
    
    public func setNodeYScale(from element: SpriteAssetElement, scale: CGFloat) {
        let node = nodeByElement[element]!
        node.yScale = scale
    }
    
    public func setSpriteColor(from element: SpriteAssetElement, color: CGColor) {
        let node = nodeByElement[element] as! SKSpriteNode
        node.color = SKColorFromCGColor(color)
    }
    
    public func setSpriteColorBlend(from element: SpriteAssetElement, colorBlend: CGFloat) {
        let node = nodeByElement[element] as! SKSpriteNode
        node.colorBlendFactor = colorBlend
    }
    
    public func setSpriteTexture(from element: SpriteAssetElement, texture: SKTexture) {
        let node = nodeByElement[element] as! SKSpriteNode
        node.texture = texture
    }
    
    public func replaceNode(for element: SpriteAssetElement, with newNode: SKNode) {
        let node = nodeByElement[element]!
        let nodeIndex = node.parent!.children.firstIndex(where: { $0 === node })!
        node.parent!.insertChild(newNode, at: nodeIndex)
        node.removeFromParent()
        for childNode in node.children {
            childNode.removeFromParent()
            newNode.addChild(childNode)
        }
        newNode.name = element.name
        newNode.isHidden = node.isHidden
        newNode.position = node.position
        newNode.zRotation = node.zRotation
        newNode.xScale = node.xScale
        newNode.yScale = node.yScale
        nodeByElement[element] = newNode
    }
    
    public func updateElement(_ element: SpriteAssetElement, with animationData: SpriteAssetElementAnimationData, applyDefaults: Bool) {
        guard var node = nodeByElement[element] else { return }
        
        let ed = animationData.elementData
        
        if applyDefaults {
            node.isHidden = !ed.visible
            node.position = ed.offset
            node.zRotation = CGFloat(ed.rotation)
            node.xScale = ed.scale.x
            node.yScale = ed.scale.y
            
            if let spriteLocator = ed.spriteLocator {
                var sprite: SKSpriteNode! = node as? SKSpriteNode
                if sprite == nil {
                    sprite = SKSpriteNode()
                    replaceNode(for: element, with: sprite)
                    node = sprite
                }
                sprite.texture = Atlases[spriteLocator]!
                sprite.color = SKColorFromCGColor(ed.color)
                sprite.colorBlendFactor = CGFloat(ed.colorBlend)
            }
        }
        
        for (trackType, _) in animationData.animatedTracks {
            switch trackType {
            case .visibility:
                node.isHidden = !ed.visible
            case .xOffset:
                node.position.x = ed.offset.x
            case .yOffset:
                node.position.y = ed.offset.y
            case .rotation:
                node.zRotation = CGFloat(ed.rotation)
            case .xScale:
                node.xScale = ed.scale.x
            case .yScale:
                node.yScale = ed.scale.y
            case .color:
                var sprite: SKSpriteNode! = node as? SKSpriteNode
                if sprite == nil {
                    sprite = SKSpriteNode()
                    replaceNode(for: element, with: sprite)
                    node = sprite
                }
                sprite.color = SKColorFromCGColor(ed.color)
            case .colorBlendFactor:
                var sprite: SKSpriteNode! = node as? SKSpriteNode
                if sprite == nil {
                    sprite = SKSpriteNode()
                    replaceNode(for: element, with: sprite)
                    node = sprite
                }
                sprite.colorBlendFactor = CGFloat(ed.colorBlend)
            case .sprite:
                if let spriteLocator = ed.spriteLocator {
                    var sprite: SKSpriteNode! = node as? SKSpriteNode
                    if sprite == nil {
                        sprite = SKSpriteNode()
                        replaceNode(for: element, with: sprite)
                        node = sprite
                    }
                    sprite.texture = Atlases[spriteLocator]!
                }
                else if node is SKSpriteNode {
                    node = SKNode()
                    replaceNode(for: element, with: node)
                }
            }
        }
    }
    
}
