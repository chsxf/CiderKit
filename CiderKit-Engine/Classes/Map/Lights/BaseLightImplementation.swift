import Foundation
import SpriteKit

public class BaseLightImplementation<T: LightDescriptor>: LightImplementation, ObservableObject {

    public var description: T
    open var matrix: matrix_float3x3 { fatalError("Missing implementation") }

    public var id: UUID { description.id }

    public var color: CGColor {
        get { description.color }
        set { description = description.mutated(withColor: newValue) }
    }
    
    public required convenience init() {
        self.init(from: T())
    }
    
    public required init(from description: T) {
        self.description = description
    }
    
    open func match(description: T) {
        if self.description.id != description.id || self.description.version != description.version {
            self.description = description
        }
    }
    
    public func reset() {
        self.description = T()
    }
    
}
