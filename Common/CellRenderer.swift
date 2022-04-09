import Foundation

public struct CellRenderer {
    
    public let groundMaterial: BaseMaterial
    public let leftElevationMaterial: BaseMaterial
    public let rightElevationMaterial: BaseMaterial
    
    public init(groundMaterial: BaseMaterial, leftElevationMaterial: BaseMaterial, rightElevationMaterial: BaseMaterial) {
        self.groundMaterial = groundMaterial
        self.leftElevationMaterial = leftElevationMaterial
        self.rightElevationMaterial = rightElevationMaterial
    }
    
}
