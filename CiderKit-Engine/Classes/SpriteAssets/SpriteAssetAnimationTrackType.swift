import Foundation

public enum SpriteAssetAnimationTrackType: String, CaseIterable, CustomStringConvertible {
    
    case visibility
    case xOffset
    case yOffset
    case rotation
    case xScale
    case yScale
    case color
    case colorBlendFactor
    case sprite
    
    private static let uppercaseSeparatorRE = try! NSRegularExpression(pattern: "[A-Z]")
    
    public var description: String {
        let transformed = Self.uppercaseSeparatorRE.stringByReplacingMatches(in: rawValue, range: NSMakeRange(0, rawValue.count), withTemplate: " $0")
        return transformed.capitalized
    }
    
    public var systemSymbolName: String {
        switch self {
        case .visibility:
            return "eye.fill"
        case .xOffset, .yOffset:
            return "arrow.up.and.down.and.arrow.left.and.right"
        case .rotation:
            return "arrow.clockwise"
        case .xScale, .yScale:
            return "arrow.up.backward.and.arrow.down.forward"
        case .color:
            return "paintpalette.fill"
        case .colorBlendFactor:
            return "eyedropper.halffull"
        case .sprite:
            return "photo"
        }
    }
    
}
