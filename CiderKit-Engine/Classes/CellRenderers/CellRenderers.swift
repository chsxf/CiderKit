import Foundation

public enum CellRenderersError: Error {
    case alreadyExisting
    case notRegistered
}

final public actor CellRenderers {

    private static var renderers: [String: CellRenderer] = [:]
    
    public static func register(cellRenderer: CellRenderer, named name: String) throws {
        if renderers[name] != nil {
            throw CellRenderersError.alreadyExisting
        }
        
        renderers[name] = cellRenderer
    }
    
    public static func unregister(named name: String) {
        renderers[name] = nil
    }
    
    public static subscript(name: String) -> CellRenderer {
        get throws {
            guard let renderer = renderers[name] else {
                throw CellRenderersError.notRegistered
            }
            return renderer
        }
    }
    
}
