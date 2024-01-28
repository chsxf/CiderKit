import SpriteKit

extension SKAction {

    public func setupTimingFunction(_ timingMode: SKActionTimingMode, partialTimeScaling: Float? = nil) {
        self.timingMode = .linear
    
        let timingFunction: SKActionTimingFunction
        switch timingMode {
        case .easeIn:
            timingFunction = AssetAnimationKey.easeInInterpolationFunction(time:)
        case .easeOut:
            timingFunction = AssetAnimationKey.easeOutInterpolationFunction(time:)
        case .easeInEaseOut:
            timingFunction = AssetAnimationKey.easeInEaseOutInterpolationFunction(time:)
        default:
            timingFunction = AssetAnimationKey.linearInterpolationFunction(time:)
        }
        
        if let partialTimeScaling, partialTimeScaling > 0, partialTimeScaling <= 1 {
            self.timingFunction = { timingFunction($0 * partialTimeScaling) }
        }
        else {
            self.timingFunction = timingFunction
        }
    }
    
}
