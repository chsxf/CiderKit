import Foundation

public enum CKUILoaderErrors: Error {
    case urlLoadingError
    case unknownErrorDuringParsing
    case missingRequiredAttribute(elementName: String, attributeName: String)
    
    case alreadyRegisteredComponentType(name: String)
    case unregisteredComponentType(name: String)
    case componentClassNotFound(className: String)
    case invalidClassType(className: String)

    case missingCustomData(name: String)
    case invalidCustomDataValue(name: String, value: String)
}

public struct NodeDescriptor: Sendable {
    fileprivate let type: String
    fileprivate let identifier: String?
    fileprivate var classes: [String]?

    fileprivate var style: String?
    fileprivate var customData: [String: String] = [:]

    fileprivate var children: [NodeDescriptor] = []
}

fileprivate final class ParserDelegate: NSObject, XMLParserDelegate {

    private var nodeStack: [NodeDescriptor] = []

    var rootNodeDescriptors = [NodeDescriptor]()
    var detectedError: CKUILoaderErrors? = nil

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "element":
            var nodeDescriptor = NodeDescriptor(type: attributeDict["type"] ?? "container", identifier: attributeDict["id"])
            if let classes = attributeDict["class"] {
                nodeDescriptor.classes = classes.split(separator: " ").map { String($0) }
            }
            nodeStack.append(nodeDescriptor)

        case "style", "data":
            guard let name = attributeDict["name"] else {
                detectedError = .missingRequiredAttribute(elementName: elementName, attributeName: "name")
                parser.abortParsing()
                return
            }
            guard let value = attributeDict["value"] else {
                detectedError = .missingRequiredAttribute(elementName: elementName, attributeName: "value")
                parser.abortParsing()
                return
            }
            var currentNodeDescriptor = nodeStack.removeLast()
            if elementName == "style" {
                currentNodeDescriptor.style = (currentNodeDescriptor.style ?? "") + "\(name): \(value);"
            }
            else {
                currentNodeDescriptor.customData[name] = value
            }
            nodeStack.append(currentNodeDescriptor)

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard elementName == "element" else { return }

        let currentNodeDescriptor = nodeStack.removeLast()
        if nodeStack.isEmpty {
            rootNodeDescriptors.append(currentNodeDescriptor)
        }
        else {
            nodeStack[nodeStack.count - 1].children.append(currentNodeDescriptor)
        }
    }

}

@globalActor
final actor CKUILoader {

    static var shared: CKUILoader = CKUILoader()
    typealias ActorType = CKUILoader

    static func loadNodeDescriptors(contentsOf url: URL) async throws -> [NodeDescriptor] {
        guard let parser = XMLParser(contentsOf: url) else {
            throw CKUILoaderErrors.urlLoadingError
        }

        let delegate = ParserDelegate()
        parser.delegate = delegate
        guard parser.parse() else {
            if let detectedError = delegate.detectedError {
                throw detectedError
            }
            else if let error = parser.parserError {
                throw error
            }
            else {
                throw CKUILoaderErrors.unknownErrorDuringParsing
            }
        }

        return delegate.rootNodeDescriptors
    }

    @MainActor
    @discardableResult
    static func createNodes(with descriptors: [NodeDescriptor], into parent: CKUIBaseNode? = nil) throws -> [CKUIBaseNode] {
        var loadedNodes = [CKUIBaseNode]()
        for descriptor in descriptors {
            let node = try Self.createNode(with: descriptor)
            loadedNodes.append(node)
        }
        if let parent {
            for node in loadedNodes {
                parent.addChild(node)
            }
        }

        return loadedNodes
    }

    @MainActor
    fileprivate static func createNode(with descriptor: NodeDescriptor) throws -> CKUIBaseNode {
        var style: CKUIStyle? = nil
        if let elementStyleAttributes = descriptor.style {
            style = CKUIStyle(attributes: elementStyleAttributes)
        }

        let nodeClass = try! CKUINodeTypeRegistry.getNodeClass(with: descriptor.type)
        let parsedCustomData = try nodeClass.parseCustomData(descriptor.customData)
        let node = nodeClass.init(type: descriptor.type, identifier: descriptor.identifier, classes: descriptor.classes, style: style, customData: parsedCustomData)
        for childDescriptor in descriptor.children {
            let childNode = try createNode(with: childDescriptor)
            node.addChild(childNode)
        }

        return node
    }

}
