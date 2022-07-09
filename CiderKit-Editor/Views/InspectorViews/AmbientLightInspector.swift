import SwiftUI
import CiderKit_Engine

struct AmbientLightInspector: View {
    
    @EnvironmentObject private var ambientLight: BaseLight
    
    private func getColor() -> Color {
        #if os(macOS)
        return Color(nsColor: ambientLight.color)
        #else
        return Color(uiColor: ambientLight.color)
        #endif
    }
    private func setColor(_ value: Color) {
        ambientLight.color = LightColor(value)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ColorPicker("Color", selection: Binding(get: getColor, set: setColor), supportsOpacity: false)
            
            Spacer()
        }
    }
    
}
