import SwiftUI
import CiderKit_Engine
import SpriteKit

struct SpriteAssetEditorView: View {
    
    private let hostingWindow: NSWindow
    
    @State private var selectedDatabaseId: String
    @State private var selectedDatabase: SpriteAssetDatabase
    @State private var zoom: Int = 4
    
    init(hostingWindow: NSWindow) {
        self.hostingWindow = hostingWindow
        let defaultDB = Project.current!.defaultSpriteAssetDatabase!
        selectedDatabase = defaultDB
        selectedDatabaseId = defaultDB.id
    }
    
    fileprivate func dismiss(response: NSApplication.ModalResponse) {
        CiderKitApp.mainWindow.endSheet(hostingWindow, returnCode: response)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Picker("Selected Database", selection: $selectedDatabaseId) {
                    ForEach(Project.current!.spriteAssetDatabases.keys.sorted(), id: \.self) { key in
                        if key != SpriteAssetDatabase.defaultDatabaseId {
                            Text(key)
                        }
                    }
                }
                
                Button("Close") {
                    dismiss(response: .OK)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Sprite Assets")
                    List {
                        ForEach(selectedDatabase.spriteAssets) { asset in
                            Text(asset.name)
                        }
                    }
                    .border(Color.gray, width: 1)
                    HStack {
                        Spacer()
                        Button("+") {
                            selectedDatabase.spriteAssets.append(SpriteAssetDescription(name: "Unnamed Sprite Asset"))
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
        .padding()
    }
}
