import Foundation

public enum ProjectErrors: String, Error {
    case notProjectFolder = "Not project folder"
    case assetDatabaseError = "Asset Database Error"
    case assetDatabaseAlreadyDefined = "Asset Database Already Defined"
    case defaultAssetDatabaseAlreadyDefined = "Default Asset Database Already Defined"
}

open class Project {
    
    public static var current: Project? = nil
    
    public let projectRoot: URL
    public let settings: ProjectSettings
    
    public var assetDatabases: [String: AssetDatabase] = [:]
    
    public var defaultAssetDatabase: AssetDatabase? {
        assetDatabase(forId: AssetDatabase.defaultDatabaseId)
    }
    
    public var atlasesDirectoryURL: URL { URL(fileURLWithPath: "Atlases", isDirectory: true, relativeTo: projectRoot) }
    public var databasesDirectoryURL: URL { URL(fileURLWithPath: "Databases", isDirectory: true, relativeTo: projectRoot) }
    public var mapsDirectoryURL: URL { URL(fileURLWithPath: "Maps", isDirectory: true, relativeTo: projectRoot) }
    public var materialDatabasesDirectoryURL: URL { URL(fileURLWithPath: "Materials", isDirectory: true, relativeTo: databasesDirectoryURL) }
    public var assetsDatabasesDirectoryURL: URL { URL(fileURLWithPath: "Assets", isDirectory: true, relativeTo: databasesDirectoryURL) }
    public var styleSheetsDirectoryURL: URL { URL(fileURLWithPath: "StyleSheets", isDirectory: true, relativeTo: projectRoot) }
    public var texturesDirectoryURL: URL { URL(fileURLWithPath: "Textures", isDirectory: true, relativeTo: projectRoot) }
    public var userInterfaceDirectoryURL: URL { URL(fileURLWithPath: "UI", isDirectory: true, relativeTo: projectRoot) }
    
    private init(projectRoot: URL) throws {
        self.projectRoot = projectRoot

        let projectSettingsFileURL = URL(fileURLWithPath: "Settings/project.cksettings", relativeTo: projectRoot)
        do {
            settings = try Functions.load(projectSettingsFileURL)
        }
        catch {
            throw ProjectErrors.notProjectFolder
        }
        
        try initAssetDatabases()
        try preloadAtlases()
        try preloadMaterialDatabases()
    }
    
    private func initAssetDatabases() throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: assetsDatabasesDirectoryURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            do {
                let fileNameRE = try NSRegularExpression(pattern: "\\.ckassetdb$")
                
                let urls = try fileManager.contentsOfDirectory(at: assetsDatabasesDirectoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                var defaultAssetDatabaseFound: Bool = false
                for url in urls {
                    let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                    if resourceValues.isDirectory ?? false {
                        continue
                    }
                    
                    let filename = url.lastPathComponent
                    if fileNameRE.firstMatch(in: filename, range: NSMakeRange(0, filename.count)) == nil {
                        continue
                    }
                    
                    let assetDatabase: AssetDatabase = try Functions.load(url)
                    assetDatabase.sourceURL = url
                    if assetDatabases[assetDatabase.id] != nil {
                        throw ProjectErrors.assetDatabaseAlreadyDefined
                    }
                    assetDatabases[assetDatabase.id] = assetDatabase
                    if assetDatabase.isDefault {
                        if defaultAssetDatabaseFound {
                            throw ProjectErrors.defaultAssetDatabaseAlreadyDefined
                        }
                        defaultAssetDatabaseFound = true
                        assetDatabases[AssetDatabase.defaultDatabaseId] = assetDatabase
                    }
                }
                
                if !defaultAssetDatabaseFound {
                    if let first = assetDatabases.first {
                        assetDatabases[AssetDatabase.defaultDatabaseId] = first.value
                    }
                }
            }
            catch let e where e is ProjectErrors {
                throw e
            }
            catch {
                print(error)
                throw ProjectErrors.assetDatabaseError
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
    
    public func assetDatabase(forId id: String) -> AssetDatabase? {
        assetDatabases[id]
    }
    
    open class func open(at url: URL) throws {
        current = try Project(projectRoot: url)
    }
    
}
