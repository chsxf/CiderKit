import Foundation
import SpriteKit

struct AtlasSpriteDescription: Codable {
    
    public let name: String
    
    private let x: CGFloat
    private let y: CGFloat
    private let w: CGFloat
    private let h: CGFloat
    
    func normalizedRect(in texture: SKTexture) -> CGRect {
        let textureSize = texture.size()
        let normalizedX = x / textureSize.width
        let normalizedY = y / textureSize.height
        let normalizedW = w / textureSize.width
        let normalizedH = h / textureSize.height
        return CGRect(x: normalizedX, y: normalizedY, width: normalizedW, height: normalizedH)
    }
    
}

struct AtlasDescription: Codable {
    
    public let texture: String
    public let sprites: [AtlasSpriteDescription]
    
    public let variants: [String: String]?
    
}
