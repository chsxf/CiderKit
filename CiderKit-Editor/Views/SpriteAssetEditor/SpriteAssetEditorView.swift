import SwiftUI
import CiderKit_Engine
import SpriteKit

struct SpriteAssetEditorView: View {
    
    private let hostingWindow: NSWindow
    
    @State private var selectedDatabaseId: String
    @State private var selectedDatabase: SpriteAssetDatabase
    
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
            
            SpriteAssetDatabaseView()
                .environmentObject(selectedDatabase)
        }
        .padding()
    }
}
