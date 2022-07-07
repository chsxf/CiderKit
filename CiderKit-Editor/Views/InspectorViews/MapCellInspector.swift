import SwiftUI
import CiderKit_Engine

struct MapCellInspector: View {
    
    @EnvironmentObject var mapCell: EditorMapCellComponent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Form {
                TextField(text: Binding(get: {
                    if let region = mapCell.region {
                        return "\(region.id)"
                    }
                    return "N/A"
                }, set: { _ in })) {
                    Text("Region")
                }
            }
            
            InspectorHeaderView("Location")
            Form {
                TextField(value: $mapCell.mapX, format: .number) {
                    Text("X")
                }
                TextField(value: $mapCell.mapY, format: .number) {
                    Text("Y")
                }
                
                TextField(text: Binding(get: {
                    if let elevation = mapCell.elevation {
                        return "\(elevation)"
                    }
                    return "N/A"
                }, set: { _ in })) {
                    Text("E")
                }
            }
            .disabled(true)
            
            Spacer()
        }
        
        if let region = mapCell.region {
            Text("Region: \(region.id)")
        }
    }
    
}

struct MapCellInspector_Previews: PreviewProvider {
    static var stubData: EditorMapCellComponent {
        return EditorMapCellComponent(mapX: 0, mapY: 4)
    }
    
    static var previews: some View {
        MapCellInspector()
            .environmentObject(stubData)
            .frame(width: 200, height: 600, alignment: .leading)
            .padding()
    }
}
