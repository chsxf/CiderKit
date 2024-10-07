import GameplayKit

public class InteractionState: GKState {

    private weak var gameView: GameView? = nil

    init(gameView: GameView) {
        super.init()
        self.gameView = gameView
    }

    var controller: InteractionController? { stateMachine as? InteractionController }

}
