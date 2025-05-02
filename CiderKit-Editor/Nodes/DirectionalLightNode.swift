import SpriteKit

class DirectionalLightNode: BaseLightNode {
    
    private static var directionalLightOnTexture: SKTexture! = nil
    private static var directionalLightOfftexture: SKTexture! = nil
    
    init() {
        if Self.directionalLightOnTexture == nil {
            Self.directionalLightOnTexture = SKTexture(imageNamed: "directional_light_on")
            Self.directionalLightOnTexture.filteringMode = .nearest
        }
        
        if Self.directionalLightOfftexture == nil {
            Self.directionalLightOfftexture = SKTexture(imageNamed: "directional_light_off")
            Self.directionalLightOfftexture.filteringMode = .nearest
        }
        
        super.init(onTexture: Self.directionalLightOnTexture, offTexture: Self.directionalLightOfftexture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
