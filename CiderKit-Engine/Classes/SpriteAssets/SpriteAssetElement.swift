import CoreGraphics

public class SpriteAssetElement: Identifiable, Hashable, Codable {
    
    enum CodingKeys: String, CodingKey {
        case name = "n"
        case offset = "o"
        case rotation = "r"
        case sprite = "s"
        case color = "cl"
        case colorBlend = "cb"
        case children = "c"
    }
    
    enum CGColorCodingKeys: String, CodingKey {
        case colorSpaceName = "csn"
        case components = "cmp"
    }
    
    public private(set) weak var parent: SpriteAssetElement? = nil
    
    public var isRoot: Bool { parent == nil }
    
    public let uuid = UUID()
    
    public var id: String {
        var result = name
        if let p = parent {
            result = "\(p.id).\(result)"
        }
        return result
    }
    
    public var name: String
    public var spriteLocator: SpriteLocator?
    public var offset: CGPoint
    public var rotation: Float
    
    public var color: CGColor
    public var colorBlend: Float
    
    public var children: [SpriteAssetElement]
    
    public init(name: String) {
        self.name = name
        offset = CGPoint()
        rotation = 0
        children = []
        color = CGColor.white
        colorBlend = 0
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        spriteLocator = try? container.decode(SpriteLocator.self, forKey: .sprite)
        offset = try container.decode(CGPoint.self, forKey: .offset)
        rotation = try container.decode(Float.self, forKey: .rotation)
        
        children = []
        var childrenSubContainer = try? container.nestedUnkeyedContainer(forKey: .children)
        if childrenSubContainer != nil {
            while !childrenSubContainer!.isAtEnd {
                let child = try childrenSubContainer!.decode(Self.self)
                children.append(child)
            }
        }
        
        if let colorSubContainer = try? container.nestedContainer(keyedBy: CGColorCodingKeys.self, forKey: .color) {
            let colorSpaceName = try colorSubContainer.decode(String.self, forKey: .colorSpaceName)
            var componentsSubContainer = try colorSubContainer.nestedUnkeyedContainer(forKey: .components)
            var components = [CGFloat]()
            while !componentsSubContainer.isAtEnd {
                components.append(try componentsSubContainer.decode(CGFloat.self))
            }
            color = CGColor(colorSpace: CGColorSpace(name: colorSpaceName as CFString)!, components: components)!
            
            colorBlend = try container.decode(Float.self, forKey: .colorBlend)
        }
        else {
            color = CGColor.white
            colorBlend = 0
        }
        
        setParentForChildren()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        if let spriteLocator = spriteLocator {
            try container.encode(spriteLocator, forKey: .sprite)
        }
        try container.encode(offset, forKey: .offset)
        try container.encode(rotation, forKey: .rotation)
        
        if !children.isEmpty {
            var subContainer = container.nestedUnkeyedContainer(forKey: .children)
            for child in children {
                try subContainer.encode(child)
            }
        }
        
        let colorSpaceName = color.colorSpace!.name! as String
        var subContainer = container.nestedContainer(keyedBy: CGColorCodingKeys.self, forKey: .color)
        try subContainer.encode(colorSpaceName, forKey: .colorSpaceName)
        var componentsContainer = subContainer.nestedUnkeyedContainer(forKey: .components)
        for component in color.components! {
            try componentsContainer.encode(component)
        }
        
        try container.encode(colorBlend, forKey: .colorBlend)
    }
    
    private func setParentForChildren() {
        for child in children {
            child.parent = self
            child.setParentForChildren()
        }
    }
    
    public func addChild(_ child: SpriteAssetElement) {
        children.append(child)
        child.parent = self
    }
    
    public func removeFromParent() {
        if let parent = parent {
            parent.children.removeAll { $0 === self }
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid.description)
    }
    
    public static func == (lhs: SpriteAssetElement, rhs: SpriteAssetElement) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
}
