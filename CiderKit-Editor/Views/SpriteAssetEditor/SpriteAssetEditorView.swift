import SwiftUI
import CiderKit_Engine

struct SpriteAssetEditorView: View {
    
    private let hostingWindow: NSWindow
    
    @State private var selectedDatabase: String
    
    init(hostingWindow: NSWindow) {
        self.hostingWindow = hostingWindow
        selectedDatabase = Project.current!.defaultSpriteAssetDatabase!.id
    }
    
    fileprivate func dismiss(response: NSApplication.ModalResponse) {
        CiderKitApp.mainWindow.endSheet(hostingWindow, returnCode: response)
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker("Selected Database", selection: $selectedDatabase) {
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
        }
        .padding()
    }
}
