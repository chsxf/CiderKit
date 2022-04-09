import GameplayKit

class CharacterComponent: GKComponent {
    
    private let diagonalRatio: CGFloat = 0.707106781186548
    
    private var map: MapNode
    private(set) var mapPosition: CGPoint
    
    var direction: CGPoint = CGPoint()
    
    var speed: CGFloat = 1
    
    private var miniMapNode: SKNode
    
    var integralX: Int { Int(round(mapPosition.x)) }
    var fractionalX: CGFloat { mapPosition.x - CGFloat(integralX) }
    var integralY: Int { Int(round(mapPosition.y)) }
    var fractionalY: CGFloat { mapPosition.y - CGFloat(integralY) }
    
    init(startPositionX x: Int, y: Int, onMap map: MapNode, miniMapNode: SKNode) {
        self.map = map
        mapPosition = CGPoint(x: x, y: y)
        
        self.miniMapNode = miniMapNode
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        var mapVector: CGPoint = CGPoint()
        if direction.x != 0 && direction.y != 0 {
            if direction.x > 0 && direction.y > 0 {
                mapVector = CGPoint(x: 0, y: 1)
            }
            else if direction.x < 0 && direction.y > 0 {
                mapVector = CGPoint(x: -1, y: 0)
            }
            else if direction.x > 0 && direction.y < 0 {
                mapVector = CGPoint(x: 1, y: 0)
            }
            else {
                mapVector = CGPoint(x: 0, y: -1)
            }
        }
        else if direction.x != 0 {
            if direction.x < 0 {
                mapVector = CGPoint(x: -diagonalRatio, y: -diagonalRatio)
            }
            else {
                mapVector = CGPoint(x: diagonalRatio, y: diagonalRatio)
            }
        }
        else if direction.y != 0 {
            if direction.y < 0 {
                mapVector = CGPoint(x: diagonalRatio, y: -diagonalRatio)
            }
            else {
                mapVector = CGPoint(x: -diagonalRatio, y: diagonalRatio)
            }
        }
        mapVector.x *= speed * CGFloat(seconds)
        mapVector.y *= speed * CGFloat(seconds)
        
        mapPosition = mapPosition.applying(CGAffineTransform(translationX: mapVector.x, y: mapVector.y))
        
        guard
            let worldPosition = map.getWorldPosition(atCellX: integralX, y: integralY),
            let node = entity?.component(ofType: GKSKNodeComponent.self)?.node
        else {
            return
        }
        
        var transformedMapVector = CGPoint(x: fractionalX, y: fractionalY)
        transformedMapVector = transformedMapVector.applying(CGAffineTransform(rotationAngle: .pi * -45.0 / 180.0))
        transformedMapVector = transformedMapVector.applying(CGAffineTransform(scaleX: sqrt(2), y: sqrt(2)))
        transformedMapVector = transformedMapVector.applying(CGAffineTransform(scaleX: CGFloat(MapNode.halfWidth), y: CGFloat(MapNode.halfHeight)))
        
        node.position = CGPoint(
            x: round(worldPosition.x + transformedMapVector.x),
            y: round(worldPosition.y + transformedMapVector.y)
        )
        
        miniMapNode.position = mapPosition.applying(CGAffineTransform(scaleX: 16, y: 16))
    }
    
}
