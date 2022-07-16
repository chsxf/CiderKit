public class SpriteAssetElement: Identifiable, Hashable, Codable {
    
    enum CodingKeys: String, CodingKey {
        case name = "n"
        case offset = "o"
        case rotation = "r"
        case sprite = "s"
        case children = "c"
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
    
    public var children: [SpriteAssetElement]
    
    public init(name: String) {
        self.name = name
        offset = CGPoint()
        rotation = 0
        children = []
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: CodingKeys.name)
        spriteLocator = try? container.decode(SpriteLocator.self, forKey: .sprite)
        offset = try container.decode(CGPoint.self, forKey: CodingKeys.offset)
        rotation = try container.decode(Float.self, forKey: CodingKeys.rotation)
        
        children = []
        var subContainer = try? container.nestedUnkeyedContainer(forKey: CodingKeys.children)
        if subContainer != nil {
            while !subContainer!.isAtEnd {
                let child = try subContainer!.decode(Self.self)
                children.append(child)
            }
        }
        
        setParentForChildren()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: CodingKeys.name)
        if let spriteLocator = spriteLocator {
            try container.encode(spriteLocator, forKey: .sprite)
        }
        try container.encode(offset, forKey: CodingKeys.offset)
        try container.encode(rotation, forKey: CodingKeys.rotation)
        
        if !children.isEmpty {
            var subContainer = container.nestedUnkeyedContainer(forKey: CodingKeys.children)
            for child in children {
                try subContainer.encode(child)
            }
        }
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
