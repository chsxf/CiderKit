import GameplayKit

open class InteractionState: GKState {

    private weak var gameView: GameView? = nil

    public init(gameView: GameView) {
        super.init()
        self.gameView = gameView
    }

    var controller: InteractionController? { stateMachine as? InteractionController }

}
