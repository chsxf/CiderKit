open class AppCore {
    
    typealias InteractionContextStackData = (type: InteractionContext.Type, instance: InteractionContext)
    
    public var gameView: GameView
    
    public private(set) var transitioning: Bool = false
    
    private var interactionContextStack = [InteractionContextStackData]()
    public var currentInteractionContext: InteractionContext? { interactionContextStack.last?.instance }
    
    public init(gameView: GameView) {
        self.gameView = gameView
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
        
        let currentContextWillRemainOnStack = strategy == .additive
        
        if currentContextWillRemainOnStack {
            await currentContextData?.instance.willLoseFocus(to: contextClass)
        }
        else {
            await currentContextData?.instance.willExit(to: contextClass)
        }
        if destinationIsAlreadyOnStack {
            await destinationContextData.instance.willGainFocus(from: currentContextData?.type)
        }
        else {
            await destinationContextData.instance.willEnter(from: currentContextData?.type)
        }
        
        interactionContextStack.removeLast()
        interactionContextStack.removeAll { $0.type === contextClass }
        interactionContextStack.append(destinationContextData)
        
        if currentContextWillRemainOnStack {
            await currentContextData?.instance.didLoseFocus(to: contextClass)
        }
        else {
            await currentContextData?.instance.didExit(to: contextClass)
        }
        if destinationIsAlreadyOnStack {
            await destinationContextData.instance.didGainFocus(from: currentContextData?.type)
        }
        else {
            await destinationContextData.instance.didEnter(from: currentContextData?.type)
        }
        
        transitioning = false
    }
    
    public func moveBackToPreviousInteractionContext() async throws {
        if interactionContextStack.count < 2 {
            throw InteractionContextError.noPreviousContext
        }
        
        try await moveTo(interactionContext: interactionContextStack[interactionContextStack.endIndex - 2].type)
    }
    
    public func interactionContextInstance<T: InteractionContext>(for contextClass: T.Type) -> InteractionContext? {
        let contextStackData = interactionContextStack.first { $0.type == contextClass }
        return contextStackData?.instance
    }
    
}
