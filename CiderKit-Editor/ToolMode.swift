struct ToolMode: OptionSet, Hashable {

    let rawValue: Int
    
    static let select = ToolMode(rawValue: 1)
    static let move = ToolMode(rawValue: 2)
    static let elevation = ToolMode(rawValue: 4)
    static let erase = ToolMode(rawValue: 8)
    
}
