final class RemoteCacheManager {
    
    private class var cachesDirectory: URL {
        var cachesDirectory: URL
        if #available(macOS 13.0, *) {
            cachesDirectory = URL(filePath: "CiderKit", directoryHint: .isDirectory, relativeTo: URL.cachesDirectory)
        } else {
            let fileManager = FileManager.default
            let libraryURL = URL(fileURLWithPath: "Library", isDirectory: true, relativeTo: fileManager.homeDirectoryForCurrentUser)
            let mainCachesDirectory = URL(fileURLWithPath: "Caches", isDirectory: true, relativeTo: libraryURL)
            cachesDirectory = URL(fileURLWithPath: "CiderKit", isDirectory: true, relativeTo: mainCachesDirectory)
        }
        return cachesDirectory
    }
    
    private class func createCacheDirectoryIfNeeded() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cachesDirectory.path) {
            try fileManager.createDirectory(at: cachesDirectory, withIntermediateDirectories: false)
        }
    }
    
    class func get(url: URL) throws -> URL {
        let filename = "\(url.absoluteString.toSHA256())-\(url.lastPathComponent)"
        
        var cachesURL: URL
        if #available(macOS 13.0, *) {
            cachesURL = URL(filePath: filename, directoryHint: .notDirectory, relativeTo: cachesDirectory)
        } else {
            cachesURL = URL(fileURLWithPath: filename, relativeTo: cachesDirectory)
        }
        
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: cachesURL.path)
        var shouldWriteToCache: Bool = !fileExists
        if fileExists {
            let fileAttributes = try fileManager.attributesOfItem(atPath: cachesURL.path)
            if let modificationDate = fileAttributes[.modificationDate] as? Date {
                shouldWriteToCache = modificationDate.timeIntervalSinceNow > 86400 // Cache is more than a day
            }
        }
        if shouldWriteToCache {
            let schemaContents = try String(contentsOf: url)
            try schemaContents.write(to: cachesURL, atomically: true, encoding: .utf8)
        }
        return cachesURL
    }
    
}
