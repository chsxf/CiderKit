import Foundation

class EditorFunctions {
    static func save<T: Codable>(_ data: T, to url: URL, prettyPrint: Bool) throws {
        let encoder = JSONEncoder()
        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        else {
            encoder.outputFormatting = .sortedKeys
        }
        let encodedData = try encoder.encode(data)
        try encodedData.write(to: url)
    }
}
