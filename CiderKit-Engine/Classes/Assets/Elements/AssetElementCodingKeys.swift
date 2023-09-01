public struct AssetElementCodingKeys: CodingKey {
    
    public var stringValue: String
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    public var intValue: Int?
    
    public init?(intValue: Int) {
        return nil
    }
    
}
