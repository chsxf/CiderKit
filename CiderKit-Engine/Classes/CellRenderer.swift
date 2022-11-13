import Foundation

public enum CellRendererError: Error {
    case invalidResetPolicy
}

public enum CellRendererMaterialResetPolicy: Int, Codable {
    case inherit = 0
    case resetWithEachCell = 1
    case resetWithEachRegion = 2
    case resetAlways = 3
}

struct CellRendererDescription: Codable {
    enum CodingKeys: String, CodingKey {
        case groundMaterialName = "g"
        case leftElevationMaterialName = "l"
        case rightElevationMaterialName = "r"
        case resetPolicy = "rp"
    }
    
    let groundMaterialName: String
    let leftElevationMaterialName: String
    let rightElevationMaterialName: String
    let resetPolicy: CellRendererMaterialResetPolicy
    
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
    
    init(from description: CellRendererDescription) {
        self.init(groundMaterialName: description.groundMaterialName, leftElevationMaterialName: description.leftElevationMaterialName, rightElevationMaterialName: description.rightElevationMaterialName, resetPolicy: description.resetPolicy)
    }
    
    public init(groundMaterialName: String, leftElevationMaterialName: String, rightElevationMaterialName: String, resetPolicy: CellRendererMaterialResetPolicy = .resetAlways) {
        self.groundMaterialName = groundMaterialName
        self.leftElevationMaterialName = leftElevationMaterialName
        self.rightElevationMaterialName = rightElevationMaterialName
        self.resetPolicy = (resetPolicy == .inherit) ? .resetAlways : resetPolicy
    }
    
}
