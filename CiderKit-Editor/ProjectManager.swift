import Foundation
import AppKit

enum ProjectManagerErrors: String, Error {
    case unableToCreateSettingsFolder = "Unable to create Settings folder"
    case unableToCreateProjectSettings = "Unable to create project settings"
}

struct RecentProject: Identifiable {
    let id = UUID()
    let url: URL
}

class ProjectManager: ObservableObject {
    public static let projectClosed = NSNotification.Name(rawValue: "ckProjectClosed")
    public static let projectOpened = NSNotification.Name(rawValue: "ckProjectOpened")
    
    @Published var recentProjects: [RecentProject]
    
    fileprivate static var singleInstance: ProjectManager? = nil
    static var `default`: ProjectManager {
        if singleInstance == nil {
            singleInstance = ProjectManager()
        }
        return singleInstance!
    }
    
    private init() {
        recentProjects = []

        for url in NSDocumentController.shared.recentDocumentURLs {
            if url.isFileURL {
                let isReachable: Bool = (try? url.checkResourceIsReachable()) ?? false
                if isReachable {
                    recentProjects.append(RecentProject(url: url))
                }
            }
        }
    }
    
    class func openProject(at url: URL) throws {
        NotificationCenter.default.post(name: Self.projectClosed, object: nil)
        
        try Project.open(at: url)
        
        NotificationCenter.default.post(name: Self.projectOpened, object: nil)
        
        var found = false
        for recent in Self.default.recentProjects {
            if recent.url == url {
                found = true
                break
            }
        }
        if !found {
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            Self.default.recentProjects.append(RecentProject(url: url))
        }
    }
    
    class func createNewProject(at url: URL) throws {
        let directoryContents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [])
        if !directoryContents.isEmpty {
            let notEmptyAlert = NSAlert()
            notEmptyAlert.messageText = "Selector folder is not empty.\nAre you sure you want to continue?"
            notEmptyAlert.informativeText = "Confirmation"
            notEmptyAlert.alertStyle = .warning
            notEmptyAlert.addButton(withTitle: "Yes")
            notEmptyAlert.addButton(withTitle: "No")
            if notEmptyAlert.runModal() != .alertFirstButtonReturn {
                return
            }
        }
        
        let foldersToCreate = [ "Settings", "Maps", "Materials", "Textures", "Sounds", "Music" ]
        do {
            for folder in foldersToCreate {
                let folderURL = URL(fileURLWithPath: folder, relativeTo: url)
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            }
        }
        catch {
            throw ProjectManagerErrors.unableToCreateSettingsFolder
        }
        
        let settingsFolderURL = URL(fileURLWithPath: "Settings", relativeTo: url)
        let projectSettingsFileURL = URL(fileURLWithPath: "project.cksettings", relativeTo: settingsFolderURL)
        let projectSettings = ProjectSettings()
        do {
            try EditorFunctions.save(projectSettings, to: projectSettingsFileURL, prettyPrint: true)
        }
        catch {
            throw ProjectManagerErrors.unableToCreateProjectSettings
        }
        
        try openProject(at: url)
    }
}
