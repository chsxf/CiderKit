import SpriteKit
import CiderKit_Engine
import GameplayKit

class WorldGrid: SKNode {
    
    enum GridElement: CaseIterable {
        case Base
        case Left
        case Right
        case Top
        case Bottom
        case TopLeft
        case TopRight
        case BottomLeft
        case BottomRight
    }
    
    private let triaxis: SKSpriteNode
    
    private var gridTileTextures = [GridElement:SKTexture]()
    
    let gridBlockSize: CGSize
    
    private var spritePools = [GridElement:SpritePool]()
    
    private var currentViewport: CGRect = CGRect()
    
    private var hoverableEntitiesByPosition: [IntPoint: GKEntity] = [:]
    
    var hoverableEntities: [GKEntity] { [GKEntity](hoverableEntitiesByPosition.values) }
    
    override init() {
        let atlas = Atlases["grid"]!
        
        triaxis = SKSpriteNode(texture: atlas["triaxis"])
        triaxis.anchorPoint = ScenePosition(x: 0.5, y: 0.32)
        triaxis.zPosition = 10000

        for element in GridElement.allCases {
            gridTileTextures[element] = atlas["grid_tile_\(element)"]
            spritePools[element] = SpritePool()
        }
        
        gridBlockSize = CGSize(width: MapNode.tileSize.width * 10, height: MapNode.tileSize.height * 10)

        super.init()
        
        addChild(triaxis)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func worldCoordinatesToGridBlock(_ point: WorldPosition) -> IntPoint {
        let tenPoint = (point / 10.0).rounded(.awayFromZero) * 10
        return IntPoint(x: Int(tenPoint.x), y: Int(tenPoint.y))
    }
    
    func update(withViewport viewport: CGRect) {
        if viewport == currentViewport {
            return
        }
        currentViewport = viewport
        
        let viewportTopLeft = ScenePosition(x: viewport.origin.x, y: viewport.origin.y + viewport.size.height)
        let transformedViewportTopLeft = MapNode.sceneToWorld(viewportTopLeft)
        let roundedViewportTopLeft = worldCoordinatesToGridBlock(transformedViewportTopLeft)
        
        let viewportBottomLeft = viewport.origin
        let transformedViewportBottomLeft = MapNode.sceneToWorld(viewportBottomLeft)
        let roundedViewportBottomLeft = worldCoordinatesToGridBlock(transformedViewportBottomLeft)
        
        let viewportTopRight = ScenePosition(x: viewport.origin.x + viewport.size.width, y: viewport.origin.y + viewport.size.height)
        let transformedViewportTopRight = MapNode.sceneToWorld(viewportTopRight)
        let roundedViewportTopRight = worldCoordinatesToGridBlock(transformedViewportTopRight)
        
        let viewportBottomRight = ScenePosition(x: viewport.origin.x + viewport.size.width, y: viewport.origin.y)
        let transformedViewportBottomRight = MapNode.sceneToWorld(viewportBottomRight)
        let roundedViewportBottomRight = worldCoordinatesToGridBlock(transformedViewportBottomRight)
        
        spritePools.forEach { $1.returnAll() }
        
        for x in stride(from: roundedViewportTopLeft.x, to: roundedViewportBottomRight.x, by: 10) {
            for y in stride(from: roundedViewportTopRight.y, to: roundedViewportBottomLeft.y, by: 10) {
                buildGridBlock(atMapPosition: MapPosition(x: x, y: y), withViewport: viewport)
            }
        }
    }
    
    private func getSprite(withElement element: GridElement) -> SKSpriteNode? {
        guard let spritePool = spritePools[element] else {
            return nil
        }

        if !spritePool.hasAvailability() {
            createSprite(withElemeent: element)
        }
        
        guard let sprite = spritePool.getElement() else {
            return nil
        }
        return sprite
    }

    private func createSprite(withElemeent element: GridElement) {
        guard let spritePool = spritePools[element] else {
            return
        }
        
        let sprite = SKSpriteNode(texture: gridTileTextures[element]!)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 1)
        spritePool.returnElement(sprite)
    }
    
    private func spriteIsVisible(atCoordinates coordinates: ScenePosition, inRect rect: CGRect) -> Bool {
        let spriteRect = CGRect(x: coordinates.x - MapNode.halfTileSize.width, y: coordinates.y - MapNode.tileSize.height, width: MapNode.tileSize.width, height: MapNode.tileSize.height)
        return rect.intersects(spriteRect)
    }
    
    private func buildGridBlock(atMapPosition position: MapPosition, withViewport viewport: CGRect) {
        let sceneCoordinates = MapNode.mapToScene(position)

        for x in 0..<10 {
            for y in 0..<10 {
                var element: GridElement = .Base
                if x == 0 {
                    if y == 0 {
                        element = .TopLeft
                    }
                    else if y == 9 {
                        element = .BottomLeft
                    }
                    else {
                        element = .Left
                    }
                }
                else if x == 9 {
                    if y == 0 {
                        element = .TopRight
                    }
                    else if y == 9 {
                        element = .BottomRight
                    }
                    else {
                        element = .Right
                    }
                }
                else if y == 0 {
                    element = .Top
                }
                else if y == 9 {
                    element = .Bottom
                }
                
                let scenePosition = sceneCoordinates.applying(CGAffineTransform.init(
                    translationX: MapNode.halfTileSize.width * CGFloat(x - y),
                    y: -MapNode.halfTileSize.height * CGFloat(x + y))
                )
                if spriteIsVisible(atCoordinates: scenePosition, inRect: viewport) {
                    let sprite = getSprite(withElement: element)!
                    sprite.position = scenePosition
                    sprite.zPosition = -10
                    addChild(sprite)
                    
                    let position = IntPoint(x: position.x + x, y: position.y + y)
                    if let entity = hoverableEntitiesByPosition[position] {
                        let nodeComponent = entity.component(ofType: GKSKNodeComponent.self)!
                        nodeComponent.node = sprite
                    }
                    else {
                        let newEntity = GKEntity()
                        newEntity.addComponent(GKSKNodeComponent(node: sprite))
                        newEntity.addComponent(EditorMapCellComponent(x: position.x, y: position.y))
                        hoverableEntitiesByPosition[position] = newEntity
                    }
                }
            }
        }
    }
    
    private func gridBlockIsVisible(atCoordinates coordinates: ScenePosition, inRect rect: CGRect) -> Bool {
        let gridBlockRect = CGRect(x: coordinates.x - (gridBlockSize.width / 2), y: coordinates.y - gridBlockSize.height, width: gridBlockSize.width, height: gridBlockSize.height)
        return rect.intersects(gridBlockRect)
    }
    
}
