open class AppCore {
    
    public private(set) static var shared: AppCore!
    
    typealias InteractionContextStackData = (type: InteractionContext.Type, instance: InteractionContext)
    
    public let gameView: GameView
    
    public private(set) var transitioning: Bool = false
    
    private var interactionContextStack = [InteractionContextStackData]()
    
    private init(gameView: GameView) {
        self.gameView = gameView
    }
    
    open class func start(gameView: GameView) {
        Self.shared = .init(gameView: gameView)
    }
    
    public func moveTo<T: InteractionContext>(interactionContext contextClass: T.Type, withStategy strategy: InteractionContextFocusStrategy = InteractionContextFocusStrategy.replaceCurrent) async throws {
        if transitioning {
            throw InteractionContextError.alreadyTransitioning
        }
        
        let currentContextData = interactionContextStack.last
        let hasCurrentContext = currentContextData != nil
        
        let canMoveTo = currentContextData?.instance.canMove(to: contextClass) ?? true
        if !canMoveTo {
            throw InteractionContextError.invalidTransition
        }
        
        transitioning = true
        
        let preExistingContextData = interactionContextStack.first { $0.type == contextClass }
        let destinationIsAlreadyOnStack = preExistingContextData != nil
        let destinationContextData = preExistingContextData ?? InteractionContextStackData(type: contextClass, instance: contextClass.init())
        
        if strategy == .additive {
            await currentContextData?.instance.willLoseFocus(to: contextClass)
        }
        else if strategy == .replaceCurrent {
            await currentContextData?.instance.willExit(to: contextClass)
        }
        else {
            for i in stride(from: interactionContextStack.count - 1, through: 0, by: -1) {
                await interactionContextStack[i].instance.willExit(to: contextClass)
            }
        }
        if destinationIsAlreadyOnStack {
            await destinationContextData.instance.willGainFocus(from: currentContextData?.type)
        }
        else {
            await destinationContextData.instance.willEnter(from: currentContextData?.type)
        }
        
        if strategy == .additive {
            await currentContextData?.instance.didLoseFocus(to: contextClass)
        }
        else if strategy == .replaceCurrent {
            await currentContextData?.instance.didExit(to: contextClass)
        }
        else {
            for i in stride(from: interactionContextStack.count - 1, through: 0, by: -1) {
                await interactionContextStack[i].instance.didExit(to: contextClass)
            }
        }
        if destinationIsAlreadyOnStack {
            await destinationContextData.instance.didGainFocus(from: currentContextData?.type)
        }
        else {
            await destinationContextData.instance.didEnter(from: currentContextData?.type)
        }
        
        if strategy == .replaceCurrent {
            if hasCurrentContext {
                interactionContextStack.removeLast()
            }
        }
        else if strategy == .single {
            interactionContextStack.removeAll()
        }
        if destinationIsAlreadyOnStack {
            interactionContextStack.removeAll { $0.type === contextClass }
        }
        interactionContextStack.append(destinationContextData)
        
        transitioning = false
    }
    
    public func moveBackToPreviousInteractionContext() async throws {
        if interactionContextStack.count < 2 {
            throw InteractionContextError.noPreviousContext
        }
        
        let canMoveToPrevious = interactionContextStack.last?.instance.canMoveToPreviousContext ?? false
        if !canMoveToPrevious {
            throw InteractionContextError.invalidTransition
        }
        
        try await moveTo(interactionContext: interactionContextStack[interactionContextStack.endIndex - 2].type)
    }
    
    public func interactionContextInstance<T: InteractionContext>(for contextClass: T.Type) -> InteractionContext? {
        let contextStackData = interactionContextStack.first { $0.type == contextClass }
        return contextStackData?.instance
    }
    
}
