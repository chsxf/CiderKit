import Foundation
import SpriteKit

public class CiderKitEngine {
    
    public static var bundle: Bundle { Bundle(for: Self.self) }

    private static var _uberShader: SKShader? = nil
    public static var uberShader: SKShader {
        if _uberShader == nil {
            let source = try! String(contentsOf: bundle.url(forResource: "UberShader", withExtension: "fsh")!, encoding: .utf8)
            _uberShader = SKShader(source: source, uniforms: [
                SKUniform(name: "u_shadeMode", float: 0),
                SKUniform(name: "u_tex_size", vectorFloat2: vector_float2()),
                SKUniform(name: "u_normals_texture", texture: nil),
                SKUniform(name: "u_position_texture", texture: nil),
                SKUniform(name: "u_position_xy_ranges", vectorFloat4: vector_float4()),
                SKUniform(name: "u_position_z_range", float: 5)
            ])
            _uberShader?.attributes = [
                SKAttribute(name: "a_position", type: .vectorFloat3)
            ]
        }
        return _uberShader!
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
                SKUniform(name: "u_light0", matrixFloat3x3: matrix_float3x3([vector_float3(3, 3, 4), vector_float3(1, 1, 0.8), vector_float3(4, 5, 1)])),
                SKUniform(name: "u_light1", matrixFloat3x3: matrix_float3x3([vector_float3(5, 5, 1.5), vector_float3(1, 0.1, 0.2), vector_float3(0.5, 1, 1)])),
                SKUniform(name: "u_light2", matrixFloat3x3: matrix_float3x3([vector_float3(2.05, 0.5, 0.8), vector_float3(0.1, 0.5, 0.5), vector_float3(0.1, 0.2, 1)])),
                SKUniform(name: "u_light3", matrixFloat3x3: matrix_float3x3([vector_float3(2.05, 1.5, 0.8), vector_float3(0.1, 0.5, 0.5), vector_float3(0.1, 0.2, 1)])),
                SKUniform(name: "u_light4", matrixFloat3x3: matrix_float3x3([vector_float3(2.05, 2.5, 0.8), vector_float3(0.1, 0.5, 0.5), vector_float3(0.1, 0.2, 1)])),
                SKUniform(name: "u_light5", matrixFloat3x3: matrix_float3x3([vector_float3(2.05, 3.5, 0.8), vector_float3(0.1, 0.5, 0.5), vector_float3(0.1, 0.2, 1)])),
                SKUniform(name: "u_light6", matrixFloat3x3: matrix_float3x3([vector_float3(10, 2, 2), vector_float3(0.75, 0.5, 0), vector_float3(10, 15, 1)])),
                SKUniform(name: "u_light7", matrixFloat3x3: matrix_float3x3([vector_float3(1, 5, 1.75), vector_float3(1, 1, 1), vector_float3(0, 1, 1)])),
                SKUniform(name: "u_light8", matrixFloat3x3: matrix_float3x3([vector_float3(1, 4, 1.75), vector_float3(1, 1, 1), vector_float3(0, 1, 1)])),
                SKUniform(name: "u_light9", matrixFloat3x3: matrix_float3x3([vector_float3(1, 3, 1.75), vector_float3(1, 1, 1), vector_float3(0, 1, 1)])),
                SKUniform(name: "u_light10", matrixFloat3x3: matrix_float3x3([vector_float3(1, 2, 1.25), vector_float3(1, 1, 1), vector_float3(0, 1, 1)])),
                SKUniform(name: "u_light11", matrixFloat3x3: matrix_float3x3([vector_float3(1, 1, 1.25), vector_float3(1, 1, 1), vector_float3(0, 1, 1)])),
                SKUniform(name: "u_light12", matrixFloat3x3: matrix_float3x3([vector_float3(1, 0, 1.25), vector_float3(1, 1, 1), vector_float3(0, 1, 1)])),
                SKUniform(name: "u_light13", matrixFloat3x3: matrix_float3x3([vector_float3(2.05, 4.5, 1.05), vector_float3(0.1, 0.5, 0.5), vector_float3(0.1, 0.2, 1)])),
                SKUniform(name: "u_light14", matrixFloat3x3: matrix_float3x3([vector_float3(2.05, 5.5, 1.05), vector_float3(0.1, 0.5, 0.5), vector_float3(0.1, 0.2, 1)])),
                SKUniform(name: "u_light15", matrixFloat3x3: matrix_float3x3([vector_float3(5, 1, 1), vector_float3(1, 1, 1), vector_float3(1, 1.5, 0.5)]))
            ])
        }
        return _lightModelFinalGatheringShader!
    }
}
