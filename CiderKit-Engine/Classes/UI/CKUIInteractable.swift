fileprivate let disabledPseudoClass = "disabled"

public protocol CKUIInteractable { }

public extension CKUIInteractable where Self: CKUIBaseNode {

    var enabled: Bool {
        get { !has(pseudoClass: disabledPseudoClass) }

        set {
            if newValue {
                remove(pseudoClass: disabledPseudoClass)

                #if os(macOS)
                NotificationCenter.default.post(name: .trackingAreaRegistrationRequested, object: self)
                #endif
            }
            else {
                add(pseudoClass: disabledPseudoClass)

                #if os(macOS)
                NotificationCenter.default.post(name: .trackingAreaUnregistrationRequested, object: self)
                #endif
            }
        }
    }

}
