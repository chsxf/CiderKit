import Foundation

public enum ProjectErrors: String, Error {
    case notProjectFolder = "Not project folder"
}

open class Project {
    public static var current: Project? = nil
    
    public let url: URL
    public let settings: ProjectSettings
    
    public var mapsDirectoryURL: URL { URL(fileURLWithPath: "Maps", relativeTo: url) }
    
    private init(url: URL) throws {
        let projectSettingsFileURL = URL(fileURLWithPath: "Settings/project.cksettings", relativeTo: url)
        do {
            settings = try Functions.load(projectSettingsFileURL)
        }
        catch {
            throw ProjectErrors.notProjectFolder
        }
        
        self.url = url
    }
    
    open class func open(at url: URL) throws {
        current = try Project(url: url)
    }
}
