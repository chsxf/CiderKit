import Foundation

public struct ProjectSettings: Codable {
    public let targetResolutionWidth: Int
    public let targetResolutionHeight: Int
    
    let startMap: String?
    
    public var startMapURL: URL? {
        guard
            let currentProject = Project.current,
            let startMap = startMap
        else {
            return nil
        }
        return URL(fileURLWithPath: "Maps/\(startMap).ckmap", relativeTo: currentProject.url)
    }
    
    public init() {
        targetResolutionWidth = 640
        targetResolutionHeight = 360
        
        startMap = nil
    }
}
