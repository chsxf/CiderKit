import SwiftUI
import GameplayKit
import CiderKit_Engine

struct InspectorView: View {
    @EnvironmentObject var selectionModel: SelectionModel
    
    var body: some View {
        VStack(alignment: .leading) {
            if selectionModel.selectable == nil {
                Text("No selection")
                    .italic()
                    .foregroundColor(.gray)
            }
            else {
                Text(selectionModel.selectable!.inspectableDescription)
                    .bold()
                Spacer()
                selectionModel.selectable!.inspectorView
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
