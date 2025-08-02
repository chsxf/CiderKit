import SpriteKit
import CiderKit_Tween

extension SKAction {

    public func setupTimingFunction(_ timingMode: Easing, partialTimeScaling: Float? = nil) {
        self.timingMode = .linear
    
        let timingFunction = timingMode.easingFunction()
        if let partialTimeScaling, partialTimeScaling > 0, partialTimeScaling <= 1 {
            self.timingFunction = { timingFunction($0 * partialTimeScaling) }
        }
        else {
            self.timingFunction = timingFunction
        }
    }
    
}
