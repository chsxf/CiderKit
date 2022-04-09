import Foundation
import SpriteKit
import GameplayKit

public class RandomizedMaterial: BaseMaterial {
    
    private var random: GKMersenneTwisterRandomSource!
    
    public var seed: UInt64 { random.seed }
    
    public init(spriteSequences: [SKAction], seed: UInt64?, shader: SKShader? = nil, shared: Bool = true) {
        random = GKMersenneTwisterRandomSource(seed: seed ?? UInt64.random(in: UInt64.min...UInt64.max))
        super.init(spriteSequences: spriteSequences, shader: shader, shared: shared)
    }
    
    override public func nextSpriteSequence() -> SKAction {
        return spriteSequences[random.nextInt(upperBound: spriteSequences.count)]
    }
    
    override public func reset() {
        random = GKMersenneTwisterRandomSource(seed: seed)
    }
    
    public override func clone() -> BaseMaterial {
        return RandomizedMaterial(spriteSequences: spriteSequences, seed: seed, shader: shader, shared: shared)
    }
    
}
