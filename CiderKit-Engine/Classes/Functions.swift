import Foundation

public final class Functions {
    
    public static func load<T: Decodable>(_ url: URL) throws -> T {
        let data: Data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
}
