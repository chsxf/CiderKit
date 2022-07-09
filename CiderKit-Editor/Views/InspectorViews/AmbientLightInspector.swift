import SwiftUI
import CiderKit_Engine

struct AmbientLightInspector: View {
    
    @EnvironmentObject private var ambientLight: DelayedObservableObject<BaseLight>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ColorPicker("Color", selection: $ambientLight.color, supportsOpacity: false)
            
            Spacer()
        }
    }
    
}
