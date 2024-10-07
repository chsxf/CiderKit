import GameplayKit

open class InteractionController: GKStateMachine {

    public init(states: [InteractionState]) {
        super.init(states: states)
    }

}
