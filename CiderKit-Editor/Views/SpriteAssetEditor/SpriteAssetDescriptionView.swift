import SwiftUI
import SpriteKit
import CiderKit_Engine

struct SpriteAssetDescriptionView: View {
    
    @EnvironmentObject private var spriteAssetDescription: SpriteAssetDescription
    
    @State private var zoom: Int = 4
    
    init() {
        print("Init")
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Asset Hierarchy")
                    
                    List {
                        
                    }
                    .listStyle(.bordered)
                    
                    HStack {
                        Spacer()
                        Button("+") {
                            
                        }
                        Button("-") {
                            
                        }
                    }
                }
                .frame(width: 200)
                
                ZStack(alignment: .bottomTrailing) {
                    SpriteView(scene: SKScene())
                    HStack {
                        Text("Current zoom: x\(zoom)")
                        Button("+") {
                            zoom *= 2
                        }
                        Button("100%") {
                            zoom = 1
                        }
                        .disabled(zoom == 1)
                        Button("-") {
                            if zoom > 1 {
                                zoom /= 2
                            }
                        }
                        .disabled(zoom == 1)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray)
                
                VStack(alignment: .leading, spacing: 5) {
                    InspectorHeaderView("UUID")
                    TextField(text: Binding(get: { spriteAssetDescription.id.description }, set: { _ in })) { }
                        .disabled(true)
                    
                    InspectorHeaderView("Name")
                    TextField(text: $spriteAssetDescription.name) { }
                    
                    Spacer()
                }
                .frame(width: 200)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
}

struct SpriteAssetDescriptionView_Previews: PreviewProvider {
    private static var stubAsset: SpriteAssetDescription {
        SpriteAssetDescription(name: "Sample Asset")
    }
    
    static var previews: some View {
        SpriteAssetDescriptionView()
            .environmentObject(stubAsset)
            .frame(width: 800, height: 600)
    }
}
