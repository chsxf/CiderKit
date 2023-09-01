import SpriteKit

extension SKAction {
    
    public func setupTimingFunction(_ timingMode: SKActionTimingMode) {
        self.timingMode = .linear
        switch timingMode {
        case .easeIn:
            self.timingFunction = AssetAnimationKey.easeInInterpolationFunction(time:)
        case .easeOut:
            self.timingFunction = AssetAnimationKey.easeOutInterpolationFunction(time:)
        case .easeInEaseOut:
            self.timingFunction = AssetAnimationKey.easeInEaseOutInterpolationFunction(time:)
        default:
            break
        }
    }
    
}
