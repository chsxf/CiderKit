import SpriteKit
import CoreGraphics

func SKColorFromCGColor(_ cgColor: CGColor) -> SKColor {
    #if os(macOS)
    return SKColor(cgColor: cgColor)!
    #else
    return SKColor(cgColor: cgColor)
    #endif
}
