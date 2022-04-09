import Foundation
import SpriteKit

final class Atlas {
    
    private let atlas: SKTextureAtlas
    
    init(named name: String) {
        atlas = SKTextureAtlas(named: name)
    }
    
    func preload(completionHandler: @escaping () -> Void) {
        atlas.preload {
            completionHandler()
        }
    }
    
    subscript(textureName: String) -> SKTexture {
        let texture = atlas.textureNamed(textureName)
        if texture.filteringMode != .nearest {
            texture.filteringMode = .nearest
        }
        return texture
    }
    
}
