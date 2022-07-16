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
    
    let gridTileSize: CGSize
    let halfGridTileSize: CGSize
    let gridBlockSize: CGSize
    
    private var spritePools = [GridElement:SpritePool]()
    
    private var currentViewport: CGRect = CGRect()
    
    private(set) var hoverableEntities: [GKEntity] = []
    
    override init() {
        let atlas = Atlases["grid"]!
        
        triaxis = SKSpriteNode(texture: atlas["triaxis"])
        triaxis.anchorPoint = CGPoint(x: 0.5, y: 0.32)
        triaxis.zPosition = 10000

        for element in GridElement.allCases {
            gridTileTextures[element] = atlas["grid_tile_\(element)"]
            spritePools[element] = SpritePool()
        }
        
        let tileSize = gridTileTextures[.Base]!.size()
        gridTileSize = CGSize(width: tileSize.width, height: tileSize.height - 1)
        halfGridTileSize = gridTileSize.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
        
        gridBlockSize = CGSize(width: gridTileSize.width * 10, height: gridTileSize.height * 10)
        
        super.init()
        
        addChild(triaxis)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func worldCoordinatesToGridBlock(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: (point.x / 10).rounded(.awayFromZero) * 10, y: (point.y / 10).rounded(.awayFromZero) * 10)
    }
    
    func update(withViewport viewport: CGRect) {
        if viewport == currentViewport {
            return
        }
        currentViewport = viewport
        
        let viewportTopLeft = CGPoint(x: viewport.origin.x, y: viewport.origin.y + viewport.size.height)
        let transformedViewportTopLeft = Math.sceneToWorld(viewportTopLeft, halfTileSize: halfGridTileSize)
        let roundedViewportTopLeft = worldCoordinatesToGridBlock(transformedViewportTopLeft)
        
        let viewportBottomLeft = viewport.origin
        let transformedViewportBottomLeft = Math.sceneToWorld(viewportBottomLeft, halfTileSize: halfGridTileSize)
        let roundedViewportBottomLeft = worldCoordinatesToGridBlock(transformedViewportBottomLeft)
        
        let viewportTopRight = CGPoint(x: viewport.origin.x + viewport.size.width, y: viewport.origin.y + viewport.size.height)
        let transformedViewportTopRight = Math.sceneToWorld(viewportTopRight, halfTileSize: halfGridTileSize)
        let roundedViewportTopRight = worldCoordinatesToGridBlock(transformedViewportTopRight)
        
        let viewportBottomRight = CGPoint(x: viewport.origin.x + viewport.size.width, y: viewport.origin.y)
        let transformedViewportBottomRight = Math.sceneToWorld(viewportBottomRight, halfTileSize: halfGridTileSize)
        let roundedViewportBottomRight = worldCoordinatesToGridBlock(transformedViewportBottomRight)
        
        spritePools.forEach { $1.returnAll() }
        hoverableEntities.removeAll()
        
        for x in stride(from: Int(roundedViewportTopLeft.x), to: Int(roundedViewportBottomRight.x), by: 10) {
            for y in stride(from: Int(roundedViewportTopRight.y), to: Int(roundedViewportBottomLeft.y), by: 10) {
                buildGridBlock(atX: x, y: y, withViewport: viewport)
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
    
    private func spriteIsVisible(atCoordinates coordinates: CGPoint, inRect rect: CGRect) -> Bool {
        let spriteRect = CGRect(x: coordinates.x - halfGridTileSize.width, y: coordinates.y - gridTileSize.height, width: gridTileSize.width, height: gridTileSize.height)
        return rect.intersects(spriteRect)
    }
    
    private func buildGridBlock(atX mapX: Int, y mapY: Int, withViewport viewport: CGRect) {
        let sceneCoordinates = Math.worldToScene(CGPoint(x: mapX, y: mapY), halfTileSize: halfGridTileSize)
        
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
                    translationX: halfGridTileSize.width * CGFloat(x - y),
                    y: -halfGridTileSize.height * CGFloat(x + y))
                )
                if spriteIsVisible(atCoordinates: scenePosition, inRect: viewport) {
                    let sprite = getSprite(withElement: element)!
                    sprite.position = scenePosition
                    sprite.zPosition = -10
                    addChild(sprite)
                    
                    let entity = GKEntity()
                    entity.addComponent(GKSKNodeComponent(node: sprite))
                    entity.addComponent(EditorMapCellComponent(mapX: mapX + x, mapY: mapY + y))
                    hoverableEntities.append(entity)
                }
            }
        }
    }
    
    private func gridBlockIsVisible(atCoordinates coordinates: CGPoint, inRect rect: CGRect) -> Bool {
        let gridBlockRect = CGRect(x: coordinates.x - (gridBlockSize.width / 2), y: coordinates.y - gridBlockSize.height, width: gridBlockSize.width, height: gridBlockSize.height)
        return rect.intersects(gridBlockRect)
    }
    
}
