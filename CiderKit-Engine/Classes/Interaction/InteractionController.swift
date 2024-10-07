import GameplayKit

public class InteractionController: GKStateMachine {

    init(states: [InteractionState]) {
        super.init(states: states)
    }

}
