import GameplayKit

open class InteractionState: GKState {

    var controller: InteractionController? { stateMachine as? InteractionController }

}
