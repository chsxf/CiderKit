import SwiftUI
import GameplayKit
import CiderKit_Engine

struct InspectorView: View {
    @EnvironmentObject var selectionModel: SelectionModel
    
    var body: some View {
        VStack(alignment: .leading) {
            let mapCell = selectionModel.selectable?.entity?.component(ofType: EditorMapCellComponent.self)
            if mapCell == nil {
                Text("No selection")
                    .italic()
                    .foregroundColor(.gray)
            }
            else {
                if mapCell!.region != nil {
                    Text("Region: \(mapCell!.region!.id)")
                }
                else {
                    Text("Region: NA")
                        .foregroundColor(.gray)
                }
                Spacer().frame(height: 10)
                HStack {
                    Text("X: \(mapCell!.mapX)")
                    Text("Y: \(mapCell!.mapY)")
                }
                if (mapCell!.elevation != nil) {
                    Text("Elevation: \(mapCell!.elevation!)")
                }
                else {
                    Text("Elevation: NA")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .frame(minWidth: 200, maxWidth: 200, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct InspectorViewPreviewData: Identifiable {
    let name: String
    let selectionModel: SelectionModel
    var id: String { name }
}

struct InspectorView_Previews: PreviewProvider {
    static private var previewData: [InspectorViewPreviewData] {
        return [InspectorViewPreviewData(name: "No selection", selectionModel: SelectionModel())]
    }
    
    static var previews: some View {
        ForEach(previewData) { previewEntry in
            InspectorView()
                .environmentObject(previewEntry.selectionModel)
        }
    }
}
