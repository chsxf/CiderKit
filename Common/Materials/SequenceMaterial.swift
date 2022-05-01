import Foundation
import SpriteKit

public enum OverflowMode: String {
    case PersistLast
    case Loop
    case Mirror
}

public class SequenceMaterial: BaseMaterial {
    
    enum Overrides: String {
        case overflowMode = "om"
    }
    
    private let overflowMode: OverflowMode
    
    private var currentSequenceIndex: Int = -1
    private var sequenceCount: Int = 0
    
    public init(spriteSequences: [SKAction], overflowMode: OverflowMode, shader: SKShader? = nil) {
        self.overflowMode = overflowMode
        super.init(spriteSequences: spriteSequences, shader: shader)
    }
    
    public convenience init(sprites: [SKTexture], overflowMode: OverflowMode, shader: SKShader? = nil) {
        var spriteSequences = [SKAction]()
        for sprite in sprites {
            spriteSequences.append(SKAction.setTexture(sprite, resize: true))
        }
        self.init(spriteSequences: spriteSequences, overflowMode: overflowMode, shader: shader)
    }
    
    override public func nextSpriteSequence(withLocalOverrides localOverrides: CustomSettings?) -> SKAction {
        switch overflowMode {
        case .PersistLast:
            currentSequenceIndex = min(currentSequenceIndex + 1, spriteSequences.count - 1)
        case .Loop:
            currentSequenceIndex = (currentSequenceIndex + 1) % spriteSequences.count
        case .Mirror:
            let isForward = (sequenceCount % 2 == 0)
            if isForward {
                currentSequenceIndex += 1
                if currentSequenceIndex >= spriteSequences.count {
                    currentSequenceIndex = spriteSequences.count - 1
                    sequenceCount += 1
                }
            }
            else {
                currentSequenceIndex -= 1
                if currentSequenceIndex < 0 {
                    currentSequenceIndex = 0
                    sequenceCount += 1
                }
            }
        }
        
        return spriteSequences[currentSequenceIndex]
    }
    
    override public func reset() {
        currentSequenceIndex = -1
        sequenceCount = 0
    }
    
    override public func clone(withOverrides overrides: CustomSettings?) -> BaseMaterial {
        var newOverflowMode = overflowMode
        if let overriddenOverflow = overrides?.getString(for: Overrides.overflowMode.rawValue), let overflowFromRawValue = OverflowMode(rawValue: overriddenOverflow) {
            newOverflowMode = overflowFromRawValue
        }
        return SequenceMaterial(spriteSequences: spriteSequences, overflowMode: newOverflowMode, shader: shader)
    }
    
}
