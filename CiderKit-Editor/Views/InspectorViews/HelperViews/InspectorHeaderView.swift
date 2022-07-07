import SwiftUI

struct InspectorHeaderView: View {
    
    private var label: String
    
    init(_ label: String) {
        self.label = label
    }
    
    var body: some View {
        
        Spacer().frame(height: 10)
        
        Text(label)
            .font(.subheadline)
            .foregroundColor(.secondary)
        
    }
    
}
