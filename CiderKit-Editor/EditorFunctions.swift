import Foundation

class EditorFunctions {
    static func save<T: Codable>(_ data: T, to url: URL) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            let encodedData = try encoder.encode(data)
            try encodedData.write(to: url)
            return true
        }
        catch {
            fatalError("Couldn't save data to \(url):\n\(error)")
        }
    }
}
