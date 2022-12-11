import Foundation

public protocol StringKeysProvider {
    
    var keys: any Collection<String> { get }
    
}
