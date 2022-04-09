import Foundation

class Functions {
    static func load<T: Decodable>(_ url: URL) -> T {
        let data: Data
        
        do {
            data = try Data(contentsOf: url)
        }
        catch {
            fatalError("Couldn't load \(url):\n\(error)")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        }
        catch {
            fatalError("Couldn't parse \(url) as \(T.self):\n\(error)")
        }
    }
}
