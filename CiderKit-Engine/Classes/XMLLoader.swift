final class XMLLoader {

//    class func load(url: URL, validate: Bool) throws -> XMLDocument {
//        var sourceContents = try String(contentsOf: url)
//
//        let unvalidatedDocument = try XMLDocument(xmlString: sourceContents)
//        if (!validate) {
//            return unvalidatedDocument
//        }
//
//        let unvalidatedRootElement = unvalidatedDocument.rootElement()!
//        guard
//            let schemaLocationAttribute = unvalidatedRootElement.attribute(forName: "xsi:noNamespaceSchemaLocation"),
//            let schemaLocation = schemaLocationAttribute.stringValue,
//            let schemaLocationURL = URL(string: schemaLocation)
//        else {
//            return unvalidatedDocument
//        }
//
//        if schemaLocationURL.scheme == "https" {
//            let cachedSchemaURL = try RemoteCacheManager.get(url: schemaLocationURL)
//            sourceContents = sourceContents.replacingOccurrences(of: schemaLocation, with: cachedSchemaURL.absoluteString)
//        }
//
//        return try XMLDocument(xmlString: sourceContents, options: .documentValidate)
//    }
    
}
