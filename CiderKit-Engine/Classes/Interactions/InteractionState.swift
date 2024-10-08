import GameplayKit

open class InteractionState: GKState {

    private weak var gameViewReference: GameView? = nil
    public var gameView: GameView? { gameViewReference }

    public init(gameView: GameView) {
        super.init()
        gameViewReference = gameView
    }

    var controller: InteractionController? { stateMachine as? InteractionController }

}
