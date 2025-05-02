import SpriteKit

class PointLightNode: BaseLightNode {
    
    private static var pointLightOnTexture: SKTexture! = nil
    private static var pointLightOfftexture: SKTexture! = nil
    
    init() {
        if Self.pointLightOnTexture == nil {
            Self.pointLightOnTexture = SKTexture(imageNamed: "point_light_on")
            Self.pointLightOnTexture.filteringMode = .nearest
        }
        
        if Self.pointLightOfftexture == nil {
            Self.pointLightOfftexture = SKTexture(imageNamed: "point_light_off")
            Self.pointLightOfftexture.filteringMode = .nearest
        }
        
        super.init(onTexture: Self.pointLightOnTexture, offTexture: Self.pointLightOfftexture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
