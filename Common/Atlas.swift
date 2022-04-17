import Foundation
import SpriteKit

final class Atlas {
    
    private let atlas: SKTextureAtlas
    
    init(named name: String) {
        atlas = SKTextureAtlas(named: name)
    }
    
    func preload() async {
        await atlas.preload()
    }
    
    subscript(textureName: String) -> SKTexture {
        let texture = atlas.textureNamed(textureName)
        if texture.filteringMode != .nearest {
            texture.filteringMode = .nearest
        }
        return texture
    }
    
}
