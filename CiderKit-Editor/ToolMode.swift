struct ToolMode: OptionSet, Hashable {
    let rawValue: Int
    
    static let move = ToolMode(rawValue: 1)
}
