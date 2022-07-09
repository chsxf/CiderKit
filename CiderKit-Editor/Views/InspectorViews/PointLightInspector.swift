import SwiftUI
import CiderKit_Engine

struct PointLightInspector: View {
    
    @EnvironmentObject private var pointLight: DelayedObservableObject<PointLight>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Toggle(isOn: $pointLight.enabled) {
                    Text("Enabled")
                }
                
                Spacer()

                ColorPicker(selection: $pointLight.color, supportsOpacity: false) { }
            }
            
            Group {
                InspectorHeaderView("Name")
                TextField(text: $pointLight.name) { }
            }

            Group {
                InspectorHeaderView("Position")
                Form {
                    let xBinding = $pointLight.position.x
                    HStack {
                        TextField(value: xBinding, format: .number) {
                            Text("X")
                        }
                        Stepper(value: xBinding, step: 0.1) { }
                    }

                    let yBinding = $pointLight.position.y
                    HStack {
                        TextField(value: yBinding, format: .number) {
                            Text("Y")
                        }
                        Stepper(value: yBinding, step: 0.1) { }
                    }

                    let elevationBinding = $pointLight.position.z
                    HStack {
                        TextField(value: elevationBinding, format: .number) {
                            Text("E")
                        }
                        Stepper(value: elevationBinding, step: 0.1) { }
                    }
                }
            }

            Group {
                InspectorHeaderView("Falloff")
                Form {
                    let nearBinding = $pointLight.falloff.near
                    HStack {
                        TextField(value: nearBinding, format: .number) {
                            Text("Near")
                        }
                        Stepper(value: nearBinding, step: 0.1) { }
                    }

                    let farBinding = $pointLight.falloff.far
                    HStack {
                        TextField(value: farBinding, format: .number) {
                            Text("Far")
                        }
                        Stepper(value: farBinding, step: 0.1) { }
                    }

                    let expBinding = $pointLight.falloff.exponent
                    HStack {
                        TextField(value: expBinding, format: .number) {
                            Text("Exp")
                        }
                        Stepper(value: expBinding, step: 0.1) { }
                    }
                }
            }
            
            Spacer()

            HStack {
                Button("Duplicate") {
                    
                }
                .disabled(true)
                
                Button("Delete") {

                }
                .disabled(true)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
}

struct PointLightInspector_Previews: PreviewProvider {
    static var stubData: PointLight {
        let falloff = PointLight.Falloff(near: 0.1, far: 2, exponent: 1)
        return PointLight(
            name: "Stub Light 01",
            color: .white,
            position: .zero,
            falloff: falloff
        )
    }
    
    static var previews: some View {
        PointLightInspector()
            .environmentObject(stubData)
            .frame(width: 200, height: 600, alignment: .leading)
            .padding()
    }
}
