import Foundation

public enum ProjectErrors: String, Error {
    case notProjectFolder = "Not project folder"
    case spriteAssetDatabaseError = "Sprite Asset Database Error"
    case spriteAssetDatabaseAlreadyDefined = "Sprite Asset Database Already Defined"
    case defaultSpriteAssetDatabaseAlreadyDefined = "Default Sprite Asset Database Already Defined"
}

open class Project {
    
    public static var current: Project? = nil
    
    public let projectRoot: URL
    public let settings: ProjectSettings
    
    public var spriteAssetDatabases: [String: SpriteAssetDatabase] = [:]
    
    public var defaultSpriteAssetDatabase: SpriteAssetDatabase? {
        spriteAssetDatabase(forId: SpriteAssetDatabase.defaultDatabaseId)
    }
    
    public var atlasesDirectoryURL: URL { URL(fileURLWithPath: "Atlases", isDirectory: true, relativeTo: projectRoot) }
    public var databasesDirectoryURL: URL { URL(fileURLWithPath: "Databases", isDirectory: true, relativeTo: projectRoot) }
    public var mapsDirectoryURL: URL { URL(fileURLWithPath: "Maps", isDirectory: true, relativeTo: projectRoot) }
    public var materialDatabasesDirectoryURL: URL { URL(fileURLWithPath: "Materials", isDirectory: true, relativeTo: databasesDirectoryURL) }
    public var spriteAssetsDatabasesDirectoryURL: URL { URL(fileURLWithPath: "SpriteAssets", isDirectory: true, relativeTo: databasesDirectoryURL) }
    public var texturesDirectoryURL: URL { URL(fileURLWithPath: "Textures", isDirectory: true, relativeTo: projectRoot) }
    
    private init(projectRoot: URL) throws {
        self.projectRoot = projectRoot

        let projectSettingsFileURL = URL(fileURLWithPath: "Settings/project.cksettings", relativeTo: projectRoot)
        do {
            settings = try Functions.load(projectSettingsFileURL)
        }
        catch {
            throw ProjectErrors.notProjectFolder
        }
        
        try initSpriteAssetDatabases()
        try preloadAtlases()
        try preloadMaterialDatabases()
    }
    
    private func initSpriteAssetDatabases() throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: spriteAssetsDatabasesDirectoryURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            do {
                let fileNameRE = try NSRegularExpression(pattern: "\\.ckspriteassetdb$")
                
                let urls = try fileManager.contentsOfDirectory(at: spriteAssetsDatabasesDirectoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
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
                    spriteAssetDatabase.sourceURL = url
                    if spriteAssetDatabases[spriteAssetDatabase.id] != nil {
                        throw ProjectErrors.spriteAssetDatabaseAlreadyDefined
                    }
                    spriteAssetDatabases[spriteAssetDatabase.id] = spriteAssetDatabase
                    if spriteAssetDatabase.isDefault {
                        if defaultSpriteAssetDatabaseFound {
                            throw ProjectErrors.defaultSpriteAssetDatabaseAlreadyDefined
                        }
                        defaultSpriteAssetDatabaseFound = true
                        spriteAssetDatabases[SpriteAssetDatabase.defaultDatabaseId] = spriteAssetDatabase
                    }
                }
                
                if !defaultSpriteAssetDatabaseFound {
                    if let first = spriteAssetDatabases.first {
                        spriteAssetDatabases[SpriteAssetDatabase.defaultDatabaseId] = first.value
                    }
                }
            }
            catch let e where e is ProjectErrors {
                throw e
            }
            catch {
                print(error)
                throw ProjectErrors.spriteAssetDatabaseError
            }
        }
    }
    
    private func preloadAtlases() throws {
        var atlasURLsByName = [String:URL]()
        for (name, fileName) in settings.preloadedAtlases {
            atlasURLsByName[name] = URL(fileURLWithPath: "\(fileName).ckatlas", relativeTo: atlasesDirectoryURL)
        }
        
        try Atlases.load(atlases: atlasURLsByName, withTexturesDirectoryURL: texturesDirectoryURL)
    }
    
    private func preloadMaterialDatabases() throws {
        for fileName in settings.preloadedMaterialDatabases {
            let url = URL(fileURLWithPath: "\(fileName).ckmatdb", relativeTo: materialDatabasesDirectoryURL)
            let _: Materials = try Functions.load(url)
        }
    }
    
    public func spriteAssetDatabase(forId id: String) -> SpriteAssetDatabase? {
        spriteAssetDatabases[id]
    }
    
    open class func open(at url: URL) throws {
        current = try Project(projectRoot: url)
    }
    
}
