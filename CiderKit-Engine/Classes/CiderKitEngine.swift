import Foundation
import SpriteKit

enum UberShaderShadeMode: Int {
    case `default` = 0
    case position = 1
    case normals = 2
}

public class CiderKitEngine {
    
    enum ShaderUniformName: String {
        case shadeMode = "u_shadeMode"
        case textureSize = "u_tex_size"
        case albedoTexture = "u_albedo_texture"
        case normalsTexture = "u_normals_texture"
        case positionTexture = "u_position_texture"
        case positionRanges = "u_position_ranges"
        case frameInViewSpace = "u_frame_in_view"
        case ambientLight = "u_ambient_light"
        case light0 = "u_light0"
        case light1 = "u_light1"
        case light2 = "u_light2"
        case light3 = "u_light3"
        case light4 = "u_light4"
        case light5 = "u_light5"
        case light6 = "u_light6"
        case light7 = "u_light7"
        case light8 = "u_light8"
        case light9 = "u_light9"
        case light10 = "u_light10"
        case light11 = "u_light11"
        case light12 = "u_light12"
        case light13 = "u_light13"
        case light14 = "u_light14"
        case light15 = "u_light15"
        
        static var maxLightIndex: Int { 15 }
        
        init?(lightIndex: Int) {
            if (lightIndex < 0 || lightIndex > Self.maxLightIndex) {
                return nil
            }
            self.init(rawValue: "u_light\(lightIndex)")
        }
    }

    enum ShaderAttributeName: String {
        case position = "a_position"
        case sizeAndFlip = "a_size_flip"
    }
    
    public static var bundle: Bundle { Bundle(for: Self.self) }

    private static var _clearTexture: SKTexture? = nil
    public static var clearTexture: SKTexture {
        if _clearTexture == nil {
            let dimension = 128
            let bytes = [UInt8](repeating: UInt8(0), count: dimension * dimension * 4)
            _clearTexture = SKTexture(data: Data(bytes), size: CGSize(width: dimension, height: dimension))
        }
        return _clearTexture!
    }
    
    private static var _lightModelFinalGatheringShader: SKShader? = nil
    public static var lightModelFinalGatheringShader: SKShader {
        if _lightModelFinalGatheringShader == nil {
            let source = try! String(contentsOf: bundle.url(forResource: "LightModelFinalGathering", withExtension: "fsh")!, encoding: .utf8)
            _lightModelFinalGatheringShader = SKShader(source: source, uniforms: [
                SKUniform(name: ShaderUniformName.albedoTexture.rawValue, texture: clearTexture),
                SKUniform(name: ShaderUniformName.normalsTexture.rawValue, texture: clearTexture),
                SKUniform(name: ShaderUniformName.positionTexture.rawValue, texture: clearTexture),
                SKUniform(name: ShaderUniformName.frameInViewSpace.rawValue, matrixFloat2x2: matrix_float2x2()),
                SKUniform(name: ShaderUniformName.positionRanges.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.ambientLight.rawValue, vectorFloat3: SIMD3(1, 1, 1)),
                SKUniform(name: ShaderUniformName.light0.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light1.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light2.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light3.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light4.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light5.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light6.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light7.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light8.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light9.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light10.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light11.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light12.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light13.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light14.rawValue, matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: ShaderUniformName.light15.rawValue, matrixFloat3x3: matrix_float3x3())
            ])
        }
        return _lightModelFinalGatheringShader!
    }
    
    public private(set) static var uberShaderInstances: [String:SKShader] = [:]
    
    public static func instantianteUberShader(for atlas: Atlas) -> SKShader {
        if let uberShader = uberShaderInstances[atlas.name] {
            return uberShader
        }
        
        let source = try! String(contentsOf: bundle.url(forResource: "UberShader", withExtension: "fsh")!, encoding: .utf8)
        
        let textureSize = atlas.atlasTexture.size()
        let uTexSize = SIMD2(Float(textureSize.width), Float(textureSize.height))

        let uberShader = SKShader(source: source, uniforms: [
            SKUniform(name: ShaderUniformName.shadeMode.rawValue, float: 0),
            SKUniform(name: ShaderUniformName.textureSize.rawValue, vectorFloat2: uTexSize),
            SKUniform(name: ShaderUniformName.normalsTexture.rawValue, texture: atlas.variant(for: "normals")?.atlasTexture ?? clearTexture),
            SKUniform(name: ShaderUniformName.positionTexture.rawValue, texture: atlas.variant(for: "position")?.atlasTexture ?? clearTexture),
            SKUniform(name: ShaderUniformName.positionRanges.rawValue, matrixFloat3x3: matrix_float3x3())
        ])
        uberShader.attributes = [
            SKAttribute(name: ShaderAttributeName.position.rawValue, type: .vectorFloat3),
            SKAttribute(name: ShaderAttributeName.sizeAndFlip.rawValue, type: .vectorFloat4)
        ]
        
        uberShaderInstances[atlas.name] = uberShader
        return uberShader
    }
    
    public static func releaseUberShaderInstance(_ shader: SKShader) {
        uberShaderInstances = uberShaderInstances.filter { $0.value === shader }
    }
    
    static func setUberShaderShadeMode(_ shadeMode: UberShaderShadeMode) {
        for (_, shader) in uberShaderInstances {
            if let uniform = shader.uniformNamed(ShaderUniformName.shadeMode.rawValue) {
                uniform.floatValue = Float(shadeMode.rawValue)
            }
        }
    }
    
    static func setUberShaderPositionRanges(_ positionMatrix: matrix_float3x3) {
        for (_, shader) in uberShaderInstances {
            if let uniform = shader.uniformNamed(ShaderUniformName.positionRanges.rawValue) {
                uniform.matrixFloat3x3Value = positionMatrix
            }
        }
    }
    
    public static func registerBuiltinFeatures() {
        AssetAnimationTrackType.registerBuiltinTypes()
        AssetElementTypeRegistry.registerBuiltinTypes()
        registerDefaultMaterialsAndRenderers()
    }
    
    private static func registerDefaultMaterialsAndRenderers() {
        let url = CiderKitEngine.bundle.url(forResource: "Default Materials", withExtension: "ckmatdb")
        let _: Materials = try! Functions.load(url!)
        
        let defaultRenderer = CellRenderer(
            groundMaterialName: "default_ground",
            leftElevationMaterialName: "default_elevation_left",
            rightElevationMaterialName: "default_elevation_right"
        )
        try! CellRenderers.register(cellRenderer: defaultRenderer, named: "default_cell")
    }

}
