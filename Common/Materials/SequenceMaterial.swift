import Foundation
import SpriteKit

public enum OverflowMode {
    case PersistLast
    case Loop
    case Mirror
}

public class SequenceMaterial: BaseMaterial {
    
    private let overflowMode: OverflowMode
    
    private var currentSequenceIndex: Int = -1
    private var sequenceCount: Int = 0
    
    public init(spriteSequences: [SKAction], overflowMode: OverflowMode, shader: SKShader? = nil, shared: Bool = true) {
        self.overflowMode = overflowMode
        super.init(spriteSequences: spriteSequences, shader: shader, shared: shared)
    }
    
    override public func nextSpriteSequence() -> SKAction {
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
    
    override public func clone() -> BaseMaterial {
        return SequenceMaterial(spriteSequences: spriteSequences, overflowMode: overflowMode, shader: shader, shared: shared)
    }
    
}
