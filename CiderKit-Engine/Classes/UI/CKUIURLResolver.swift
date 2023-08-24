import Foundation
import SpriteKit

public final class CKUIURLResolver {
    
    private static var resolvedTextures: [URL: SKTexture] = [:]
    
    public class func resolveTexture(url: URL) -> SKTexture {
        if let previouslyResolvedTexture = resolvedTextures[url] {
            return previouslyResolvedTexture
        }
        
        var localURL: URL? = nil
        
        switch url.scheme {
        case "http", "https":
            localURL = try! RemoteCacheManager.get(url: url)
            break
            
        case "sprite":
            if let atlasName = url.host, let atlas = Atlases[atlasName] {
                let texture = atlas[url.lastPathComponent]!
                resolvedTextures[url] = texture
                return texture
            }
            else {
                var path = url.relativePath
                if path.starts(with: "/") {
                    let substringIndex = path.index(after: path.startIndex)
                    path = String(path[substringIndex...])
                }
                localURL = URL(fileURLWithPath: path, relativeTo: Project.current!.texturesDirectoryURL)
            }
            break
            
        default:
            break
        }
        
        #if os(macOS)
        let image = NSImage(contentsOf: localURL!)!
        #else
        let data = try! Data(contentsOf: localURL!)
        let image = UIImage(data: data)!
        #endif
        
        let texture = SKTexture(image: image)
        resolvedTextures[url] = texture
        return texture
    }
    
}
