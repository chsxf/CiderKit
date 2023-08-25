import Foundation

public enum CKUILoaderErrors: Error {
    case urlLoadingError
    case unknownErrorDuringParsing
    case missingRequiredAttribute(elementName: String, attributeName: String)
    
    case alreadyRegisteredComponentType(name: String)
    case unregisteredComponentType(name: String)
    case componentClassNotFound(className: String)
    case invalidClassType(className: String)
}

fileprivate struct NodeDescriptor {
    let type: String
    let identifier: String?
    var classes: [String]?
    
    var style: String?
    var customData: [String:Any] = [:]
    
    var children: [CKUIBaseNode] = []
}

public final class CKUILoader : NSObject, XMLParserDelegate {
    
    fileprivate struct NodeTypeRegistrationData {
        let typeRepresentation: String
        let bundle: Bundle
    }
    
    fileprivate static var registeredNodeTypes: [String: NodeTypeRegistrationData] = [:]
    fileprivate static var builtinNodeTypesRegistered = false
    
    private var loadedNodes: [CKUIBaseNode] = []
    private var detectedError: CKUILoaderErrors? = nil
    
    private var nodeStack: [NodeDescriptor] = []
    
    public class func registerBuiltinComponents() {
        guard !builtinNodeTypesRegistered else { return }
        
        try! registerNodeType(CKUIContainer.self, with: "container")
        try! registerNodeType(CKUILabel.self, with: "label")
        try! registerNodeType(CKUIButton.self, with: "button")
        
        builtinNodeTypesRegistered = true
    }
    
    public class func load(contentsOf url: URL) throws -> [CKUIBaseNode] {
        guard let parser = XMLParser(contentsOf: url) else {
            throw CKUILoaderErrors.urlLoadingError
        }
        
        let delegate = Self()
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
        
        return delegate.loadedNodes
    }
    
    public class func load(contentsOf url: URL, into parent: CKUIBaseNode) throws {
        let loadedNodes = try load(contentsOf: url)
        
        for node in loadedNodes {
            parent.addChild(node)
        }
    }
    
    override fileprivate init() { }
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
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
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard elementName == "element" else { return }
        
        let currentNodeDescriptor = nodeStack.removeLast()
        
        var style: CKUIStyle? = nil
        if let elementStyleAttributes = currentNodeDescriptor.style {
            style = CKUIStyle(attributes: elementStyleAttributes)
        }
        
        let nodeClass = try! Self.getNodeClass(with: currentNodeDescriptor.type)
        let node = nodeClass.init(type: currentNodeDescriptor.type, identifier: currentNodeDescriptor.identifier, classes: currentNodeDescriptor.classes, style: style, customData: currentNodeDescriptor.customData)
        for childNode in currentNodeDescriptor.children {
            node.addChild(childNode)
        }
        
        if nodeStack.isEmpty {
            loadedNodes.append(node)
        }
        else {
            nodeStack[nodeStack.count - 1].children.append(node)
        }
    }
    
    public class func registerNodeType<T: CKUIBaseNode>(_ type: T.Type, with name: String, in bundle: Bundle? = nil) throws {
        if registeredNodeTypes[name] != nil {
            throw CKUILoaderErrors.alreadyRegisteredComponentType(name: name)
        }
        registeredNodeTypes[name] = NodeTypeRegistrationData(
            typeRepresentation: String(reflecting: type),
            bundle: bundle ?? CiderKitEngine.bundle
        )
    }
    
    fileprivate class func getNodeClass(with name: String) throws -> CKUIBaseNode.Type {
        guard let componentRegistrationData = registeredNodeTypes[name] else {
            throw CKUILoaderErrors.unregisteredComponentType(name: name)
        }
        
        guard let loadedClass = componentRegistrationData.bundle.classNamed(componentRegistrationData.typeRepresentation) else {
            throw CKUILoaderErrors.componentClassNotFound(className: componentRegistrationData.typeRepresentation)
        }
        
        guard let castedClass = loadedClass as? CKUIBaseNode.Type else {
            throw CKUILoaderErrors.invalidClassType(className: componentRegistrationData.typeRepresentation)
        }
        
        return castedClass
    }
    
}
