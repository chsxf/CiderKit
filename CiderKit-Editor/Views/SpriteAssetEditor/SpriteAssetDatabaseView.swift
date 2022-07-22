import SwiftUI
import SpriteKit
import CiderKit_Engine

struct SpriteAssetDatabaseView: View {
    @EnvironmentObject private var database: SpriteAssetDatabase
    
    @State private var zoom: Int = 4
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Sprite Assets")
                List {
                    ForEach(database.spriteAssets) { asset in
                        Text(asset.name)
                    }
                }
                .border(Color.gray, width: 1)
                HStack {
                    Spacer()
                    Button("+") {
                        database.spriteAssets.append(SpriteAssetDescription(name: "Unnamed Sprite Asset"))
                    }
                    Button("-") {
                        
                    }
                }
            }
            .frame(width: 200)
            
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Asset Hierarchy")
                        List {
                            
                        }
                        .border(Color.gray, width: 1)
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
                    
                    VStack {
                        
                    }
                    .frame(width: 200)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct SpriteAssetDatabaseView_Previews: PreviewProvider {
    static var previews: some View {
        SpriteAssetDatabaseView()
            .environmentObject(SpriteAssetDatabase(id: "test"))
    }
}
