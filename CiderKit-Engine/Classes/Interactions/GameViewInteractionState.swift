import GameplayKit

open class GameViewInteractionState: InteractionState {

    public weak var gameView: GameView? = nil

    public init(gameView: GameView) {
        super.init()
        self.gameView = gameView
    }

}
