import Foundation

public enum ProjectErrors: String, Error {
    case notProjectFolder = "Not project folder"
    case spriteAssetDatabaseError = "Sprite Asset Database Error"
    case spriteAssetDatabaseAlreadyDefined = "Sprite Asset Database Already Defined"
    case defaultSpriteAssetDatabaseAlreadyDefined = "Default Sprite Asset Database Already Defined"
}

open class Project {
    public static var current: Project? = nil
    
    public let url: URL
    public let settings: ProjectSettings
    
    public var spriteAssetDatabases: [String: SpriteAssetDatabase] = [:]
    
    public var defaultSpriteAssetDatabase: SpriteAssetDatabase? {
        spriteAssetDatabase(forId: "default")
    }
    
    public var mapsDirectoryURL: URL { URL(fileURLWithPath: "Maps", relativeTo: url) }
    
    private init(url: URL) throws {
        let projectSettingsFileURL = URL(fileURLWithPath: "Settings/project.cksettings", relativeTo: url)
        do {
            settings = try Functions.load(projectSettingsFileURL)
        }
        catch {
            throw ProjectErrors.notProjectFolder
        }
        
        let databaseFolderPath = URL(fileURLWithPath: "Databases", relativeTo: url)
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: databaseFolderPath.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            do {
                let fileNameRE = try NSRegularExpression(pattern: "\\.ckspriteassetdb$")
                
                let urls = try fileManager.contentsOfDirectory(at: databaseFolderPath, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                var defaultSpriteAssetDatabaseFound: Bool = false
                for url in urls {
                    let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                    if resourceValues.isDirectory ?? false {
                        continue
                    }
                    
                    let filename = url.lastPathComponent
                    if fileNameRE.firstMatch(in: filename, range: NSMakeRange(0, filename.count)) == nil {
                        continue
                    }
                    
                    let spriteAssetDatabase: SpriteAssetDatabase = try Functions.load(url)
                    if spriteAssetDatabases[spriteAssetDatabase.id] != nil {
                        throw ProjectErrors.spriteAssetDatabaseAlreadyDefined
                    }
                    spriteAssetDatabases[spriteAssetDatabase.id] = spriteAssetDatabase
                    if spriteAssetDatabase.isDefault {
                        if defaultSpriteAssetDatabaseFound {
                            throw ProjectErrors.defaultSpriteAssetDatabaseAlreadyDefined
                        }
                        defaultSpriteAssetDatabaseFound = true
                        spriteAssetDatabases["default"] = spriteAssetDatabase
                    }
                }
            }
            catch let e where e is ProjectErrors {
                throw e
            }
            catch {
                throw ProjectErrors.spriteAssetDatabaseError
            }
        }
        
        self.url = url
    }
    
    public func spriteAssetDatabase(forId id: String) -> SpriteAssetDatabase? {
        spriteAssetDatabases[id]
    }
    
    open class func open(at url: URL) throws {
        current = try Project(url: url)
    }
}
