import Foundation

public struct StringCodingKey: CodingKey {
    
    public var stringValue: String
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    public var intValue: Int? = nil
    
    public init?(intValue: Int) {
        return nil
    }
    
}
