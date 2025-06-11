open class InteractionContext {
    
    public required init() { }
    
    open var canMoveToPreviousContext: Bool { false }
    
    open func canMove<T: InteractionContext>(to otherContextClass: T.Type) -> Bool {
        true
    }
    
    open func willExit<T: InteractionContext>(to destinationContextClass: T.Type?) async { }
    open func willLoseFocus<T: InteractionContext>(to destinationContextClass: T.Type?) async { }
    open func willEnter<T: InteractionContext>(from previousContextClass: T.Type?) async { }
    open func willGainFocus<T: InteractionContext>(from previousContextClass: T.Type?) async { }

    open func didExit<T: InteractionContext>(to destinationContextClass: T.Type?) async { }
    open func didLoseFocus<T: InteractionContext>(to destinationContextClass: T.Type?) async { }
    open func didEnter<T: InteractionContext>(from previousContextClass: T.Type?) async { }
    open func didGainFocus<T: InteractionContext>(from previousContextClass: T.Type?) async { }
    
}
