import AppKit
import UniformTypeIdentifiers
import CiderKit_Engine

final class SpriteAssetEditor {
    
    class func open() {
        guard let project = Project.current else {
            let notProjectAlert = NSAlert()
            notProjectAlert.informativeText = "No loaded project"
            notProjectAlert.messageText = "Error"
            notProjectAlert.alertStyle = .critical
            notProjectAlert.addButton(withTitle: "Ok")
            notProjectAlert.runModal()
            return
        }
        
        if project.spriteAssetDatabases.isEmpty {
            do {
                print(project.databasesDirectoryURL)
                print(project.spriteAssetsDatabasesDirectoryURL)
                try FileManager.default.createDirectory(at: project.spriteAssetsDatabasesDirectoryURL, withIntermediateDirectories: true)
            }
            catch {
                let unableCreateDirectoryAlert = NSAlert()
                unableCreateDirectoryAlert.informativeText = "Unable to create the sprite asset databse directory into the project"
                unableCreateDirectoryAlert.messageText = "Error"
                unableCreateDirectoryAlert.alertStyle = .critical
                unableCreateDirectoryAlert.addButton(withTitle: "Ok")
                unableCreateDirectoryAlert.runModal()
                return
            }
            
            let notDatabaseAlert = NSAlert()
            notDatabaseAlert.informativeText = "The current project has no sprite asset database. Please create one."
            notDatabaseAlert.messageText = "Warning"
            notDatabaseAlert.alertStyle = .warning
            notDatabaseAlert.addButton(withTitle: "Ok")
            notDatabaseAlert.runModal()
            
            let savePanel = NSSavePanel()
            savePanel.directoryURL = project.spriteAssetsDatabasesDirectoryURL
            if let type = UTType("com.xhaleera.CiderKit.spriteAssetDatabase") {
                savePanel.allowedContentTypes = [ type ]
            }
            savePanel.prompt = "Create Sprite Asset Database"
            let response = savePanel.runModal()
            if response == .OK {
                let targetURL = savePanel.url!
                let targetURLFolder = targetURL.deletingLastPathComponent()
                if targetURLFolder != project.spriteAssetsDatabasesDirectoryURL.absoluteURL {
                    let wrongFolderAlert = NSAlert()
                    wrongFolderAlert.informativeText = "Sprite asset databases must be created in the Databases/SpriteAssets folder of your project"
                    wrongFolderAlert.messageText = "Error"
                    wrongFolderAlert.alertStyle = .critical
                    wrongFolderAlert.addButton(withTitle: "Ok")
                    wrongFolderAlert.runModal()
                    return
                }
                
                do {
                    let filenameWithoutExtension = targetURL.deletingPathExtension().lastPathComponent
                    let id = SpriteAssetDatabase.idFromFilename(filenameWithoutExtension)
                    if id.isEmpty {
                        let invalidFilenameAlert = NSAlert()
                        invalidFilenameAlert.informativeText = "The selected file name cannot be converted to a suitable Id for the sprite asset database. Unable to create the database"
                        invalidFilenameAlert.messageText = "Error"
                        invalidFilenameAlert.alertStyle = .critical
                        invalidFilenameAlert.addButton(withTitle: "Ok")
                        invalidFilenameAlert.runModal()
                        return
                    }
                    
                    let database = SpriteAssetDatabase(id: id)
                    database.isDefault = true
                    
                    try EditorFunctions.save(database, to: targetURL, prettyPrint: true)
                    project.spriteAssetDatabases[id] = database
                    project.spriteAssetDatabases[SpriteAssetDatabase.defaultDatabaseId] = database
                }
                catch {
                    let failedCreationAlert = NSAlert()
                    failedCreationAlert.informativeText = "Unable to create the new sprite asset database. The sprite asset editor cannot be opened."
                    failedCreationAlert.messageText = "Error"
                    failedCreationAlert.alertStyle = .critical
                    failedCreationAlert.addButton(withTitle: "Ok")
                    failedCreationAlert.runModal()
                    return
                }
            }
            else {
                let canceledAlert = NSAlert()
                canceledAlert.informativeText = "You chose to not create a sprite asset database. The sprite asset editor cannot be opened."
                canceledAlert.messageText = "Error"
                canceledAlert.alertStyle = .critical
                canceledAlert.addButton(withTitle: "Ok")
                canceledAlert.runModal()
                return
            }
        }
        
        openWindow()
    }
    
    private class func openWindow() {
        let windowRect: CGRect
        if let screen = CiderKitApp.mainWindow.screen {
            windowRect = CGRect(x: 0, y: 0, width: screen.frame.width * 0.8, height: screen.frame.height * 0.8)
        }
        else {
            windowRect = CGRect(x: 0, y: 0, width: 800, height: 600)
        }
        
        let window = NSWindow(contentRect: windowRect, styleMask: [.resizable, .titled], backing: .buffered, defer: false)
        window.contentView = SpriteAssetEditorView(frame: windowRect)
        
        CiderKitApp.mainWindow.beginSheet(window) { _ in

        }
    }
    
}
