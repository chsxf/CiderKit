#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct KeyEventData {

    public let keycode: UInt16
    public let characters: String?
    public let charactersIgnoringModifiers: String?

    #if os(macOS)
    public let modifierFlags: NSEvent.ModifierFlags

    public init(with event: NSEvent) {
        keycode = event.keyCode
        characters = event.characters
        charactersIgnoringModifiers = event.charactersIgnoringModifiers
        modifierFlags = event.modifierFlags.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask)
    }
    #endif

}
