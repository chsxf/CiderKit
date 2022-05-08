import Foundation
import SpriteKit
import GameplayKit

public class RandomizedMaterial: BaseMaterial {
    
    enum Overrides: String {
        case seed = "s"
    }
    
    private var random: GKMersenneTwisterRandomSource!
    
    public private(set) var fixedSeed: UInt64?
    public var seed: UInt64 { random.seed }
    
    public init(spriteSequences: [SKAction], seed: UInt64?, shader: SKShader? = nil) {
        fixedSeed = seed
        random = GKMersenneTwisterRandomSource(seed: fixedSeed ?? UInt64.random(in: UInt64.min...UInt64.max))
        super.init(spriteSequences: spriteSequences, shader: shader)
    }
    
    public convenience init(sprites: [SKTexture], seed: UInt64?, shader: SKShader? = nil) {
        var spriteSequences = [SKAction]()
        for sprite in sprites {
            spriteSequences.append(SKAction.setTexture(sprite, resize: true))
        }
        self.init(spriteSequences: spriteSequences, seed: seed, shader: shader)
    }
    
    override public func nextSpriteSequence(withLocalOverrides localOverrides: CustomSettings?) -> SKAction {
        return spriteSequences[random.nextInt(upperBound: spriteSequences.count)]
    }
    
    override public func reset() {
        random = GKMersenneTwisterRandomSource(seed: seed)
    }
    
    public override func clone(withOverrides overrides: CustomSettings?) -> BaseMaterial {
        var newSeed: UInt64? = fixedSeed
        if let overriddenSeed = overrides?.getInt(for: Overrides.seed.rawValue) {
            newSeed = UInt64(overriddenSeed)
        }
        return RandomizedMaterial(spriteSequences: spriteSequences, seed: newSeed, shader: shader)
    }
    
}
