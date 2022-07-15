import SpriteKit

protocol ToolContext: CaseIterable, Hashable {
    
    var spriteImageFormat: String { get }
    var color: SKColor { get }
    var normalizedRect: CGRect { get }
    
}
