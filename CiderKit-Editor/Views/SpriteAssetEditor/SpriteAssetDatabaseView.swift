import SwiftUI
import CiderKit_Engine

struct SpriteAssetDatabaseView: View {
    @EnvironmentObject private var database: SpriteAssetDatabase {
        didSet {
            selectedAsset = database.spriteAssets.first
            selectedAssetUUID = selectedAsset?.id
        }
    }
    
    @State private var selectedAssetUUID: UUID? = nil
    @State private var selectedAsset: SpriteAssetDescription? = nil
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Sprite Assets")
                
                List(database.spriteAssets, selection: $selectedAssetUUID) { asset in
                    Text(asset.name)
                }
                .listStyle(.bordered)
                
                HStack {
                    Spacer()
                    Button("+") {
                        let newAsset = SpriteAssetDescription(name: "Unnamed Sprite Asset")
                        database.spriteAssets.append(newAsset)
                        selectedAssetUUID = newAsset.id
                        selectedAsset = newAsset
                    }
                    Button("-") {
                        
                    }
                }
            }
            .frame(width: 200)
            
            if selectedAsset != nil {
                SpriteAssetDescriptionView()
                    .environmentObject(selectedAsset!)
            }
            else {
                Text("No selected asset")
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct SpriteAssetDatabaseView_Previews: PreviewProvider {
    static var previews: some View {
        SpriteAssetDatabaseView()
            .environmentObject(SpriteAssetDatabase(id: "test"))
    }
}
