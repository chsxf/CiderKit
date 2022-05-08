import Foundation
import SpriteKit

enum UberShaderShadeMode: Int {
    case `default` = 0
    case position = 1
    case normals = 2
}

public class CiderKitEngine {
    
    public static var bundle: Bundle { Bundle(for: Self.self) }

    private static var _clearTexture: SKTexture? = nil
    public static var clearTexture: SKTexture {
        if _clearTexture == nil {
            let dimension = 128
            let bytes = stride(from: 0, to: dimension * dimension, by: 1).flatMap { _ in
                return [ UInt8(0), UInt8(0), UInt8(0), UInt8(0) ]
            }
            _clearTexture = SKTexture(data: Data(bytes), size: CGSize(width: dimension, height: dimension))
        }
        return _clearTexture!
    }
    
    private static var _lightModelFinalGatheringShader: SKShader? = nil
    public static var lightModelFinalGatheringShader: SKShader {
        if _lightModelFinalGatheringShader == nil {
            let source = try! String(contentsOf: bundle.url(forResource: "LightModelFinalGathering", withExtension: "fsh")!, encoding: .utf8)
            _lightModelFinalGatheringShader = SKShader(source: source, uniforms: [
                SKUniform(name: "u_normals_texture", texture: nil),
                SKUniform(name: "u_position_texture", texture: nil),
                SKUniform(name: "u_frame_in_view", matrixFloat2x2: matrix_float2x2()),
                SKUniform(name: "u_ambient_light", vectorFloat3: vector_float3(0.1, 0.1, 0.1)),
                SKUniform(name: "u_position_ranges", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light0", matrixFloat3x3: matrix_float3x3([vector_float3(10, 2, 5), vector_float3(1, 1, 1), vector_float3(10, 15, 0.5)])),
                SKUniform(name: "u_light1", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light2", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light3", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light4", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light5", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light6", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light7", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light8", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light9", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light10", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light11", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light12", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light13", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light14", matrixFloat3x3: matrix_float3x3()),
                SKUniform(name: "u_light15", matrixFloat3x3: matrix_float3x3())
            ])
        }
        return _lightModelFinalGatheringShader!
    }
    
    public private(set) static var uberShaderInstances: [SKShader] = []
    
    public static func instantianteUberShader(for atlas: Atlas) -> SKShader {
        let source = try! String(contentsOf: bundle.url(forResource: "UberShader", withExtension: "fsh")!, encoding: .utf8)
        
        let textureSize = atlas.atlasTexture.size()
        let uTexSize = vector_float2(Float(textureSize.width), Float(textureSize.height))
        
        let uberShader = SKShader(source: source, uniforms: [
            SKUniform(name: "u_shadeMode", float: 0),
            SKUniform(name: "u_tex_size", vectorFloat2: uTexSize),
            SKUniform(name: "u_normals_texture", texture: atlas.variant(for: "normals")?.atlasTexture ?? clearTexture),
            SKUniform(name: "u_position_texture", texture: atlas.variant(for: "position")?.atlasTexture ?? clearTexture),
            SKUniform(name: "u_position_ranges", matrixFloat3x3: matrix_float3x3())
        ])
        uberShader.attributes = [
            SKAttribute(name: "a_position", type: .vectorFloat3)
        ]
        
        uberShaderInstances.append(uberShader)
        
        return uberShader
    }
    
    public static func releaseUberShaderInstance(_ shader: SKShader) {
        uberShaderInstances.removeAll { $0 == shader }
    }
    
    static func setUberShaderShadeMode(_ shadeMode: UberShaderShadeMode) {
        for shader in uberShaderInstances {
            if let uniform = shader.uniformNamed("u_shadeMode") {
                uniform.floatValue = Float(shadeMode.rawValue)
            }
        }
    }
    
    static func setUberShaderPositionRanges(_ positionMatrix: matrix_float3x3) {
        for shader in uberShaderInstances {
            if let uniform = shader.uniformNamed("u_position_ranges") {
                uniform.matrixFloat3x3Value = positionMatrix
            }
        }
    }

}
