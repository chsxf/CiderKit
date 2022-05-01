import Foundation

public enum CellRendererError: Error {
    case invalidResetPolicy
}

public enum CellRendererMaterialResetPolicy {
    case inherit
    case resetWithEachCell
    case resetWithEachRegion
    case resetAlways
}

public struct CellRenderer {
    
    private let groundMaterialName: String
    public var groundMaterial: BaseMaterial {
        get throws { try Materials.material(named: groundMaterialName, withOverrides: nil) }
    }
    private var _groundMaterialResetPolicy: CellRendererMaterialResetPolicy = .inherit
    public var groundMaterialResetPolicy: CellRendererMaterialResetPolicy {
        get { (_groundMaterialResetPolicy == .inherit) ? resetPolicy : _groundMaterialResetPolicy }
        set { _groundMaterialResetPolicy = newValue }
    }
    
    private let leftElevationMaterialName: String
    public var leftElevationMaterial: BaseMaterial {
        get throws { try Materials.material(named: leftElevationMaterialName, withOverrides: nil) }
    }
    private var _leftElevationMaterialResetPolicy: CellRendererMaterialResetPolicy = .resetWithEachCell
    public var leftElevationMaterialResetPolicy: CellRendererMaterialResetPolicy {
        get { (_leftElevationMaterialResetPolicy == .inherit) ? resetPolicy : _leftElevationMaterialResetPolicy }
        set { _leftElevationMaterialResetPolicy = newValue }
    }
    
    private let rightElevationMaterialName: String
    public var rightElevationMaterial: BaseMaterial {
        get throws { try Materials.material(named: rightElevationMaterialName, withOverrides: nil) }
    }
    private var _rightElevationMaterialResetPolicy: CellRendererMaterialResetPolicy = .resetWithEachCell
    public var rightElevationMaterialResetPolicy: CellRendererMaterialResetPolicy {
        get { (_rightElevationMaterialResetPolicy == .inherit) ? resetPolicy : _rightElevationMaterialResetPolicy }
        set { _rightElevationMaterialResetPolicy = newValue }
    }
    
    public let resetPolicy: CellRendererMaterialResetPolicy
    
    public init(groundMaterialName: String, leftElevationMaterialName: String, rightElevationMaterialName: String, resetPolicy: CellRendererMaterialResetPolicy = .resetAlways) {
        self.groundMaterialName = groundMaterialName
        self.leftElevationMaterialName = leftElevationMaterialName
        self.rightElevationMaterialName = rightElevationMaterialName
        self.resetPolicy = (resetPolicy == .inherit) ? .resetAlways : resetPolicy
    }
    
}
