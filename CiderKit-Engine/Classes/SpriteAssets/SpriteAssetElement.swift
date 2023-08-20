import CoreGraphics

public struct SpriteAssetElementData {
    public var visible: Bool
    public var spriteLocator: SpriteLocator?
    public var offset: CGPoint
    public var rotation: Float
    public var scale: CGPoint
    public var color: CGColor
    public var colorBlend: Float
    
    public subscript(trackType: SpriteAssetAnimationTrackType) -> Any {
        switch trackType {
        case .visibility:
            return visible
        case .color:
            return color
        case .sprite:
            return spriteLocator?.description ?? ""
        case .xOffset:
            return offset.x
        case .yOffset:
            return offset.y
        case .rotation:
            return rotation
        case .xScale:
            return scale.x
        case .yScale:
            return scale.y
        case .colorBlendFactor:
            return colorBlend
        }
    }
    
    public mutating func setValue(_ value: Any?, for trackType: SpriteAssetAnimationTrackType) {
        if let value {
            switch trackType {
            case .visibility:
                visible = value as! Bool
            case .color:
                color = value as! CGColor
            case .sprite:
                if value is SpriteLocator {
                    spriteLocator = value as? SpriteLocator
                }
                else if value is String {
                    spriteLocator = SpriteLocator(description: value as! String)
                }
                break
            case .xOffset:
                if value is CGFloat {
                    offset.x = value as! CGFloat
                }
                else if value is Float {
                    offset.x = CGFloat(value as! Float)
                }
            case .yOffset:
                if value is CGFloat {
                    offset.y = value as! CGFloat
                }
                else if value is Float {
                    offset.y = CGFloat(value as! Float)
                }
            case .rotation:
                rotation = value as! Float
            case .xScale:
                if value is CGFloat {
                    scale.x = value as! CGFloat
                }
                else if value is Float {
                    scale.x = CGFloat(value as! Float)
                }
            case .yScale:
                if value is CGFloat {
                    scale.y = value as! CGFloat
                }
                else if value is Float {
                    scale.y = CGFloat(value as! Float)
                }
            case .colorBlendFactor:
                colorBlend = value as! Float
            }
        }
    }
}

public class SpriteAssetElement: Hashable, Codable {
    
    enum CodingKeys: String, CodingKey {
        case uuid = "id"
        case name = "n"
        case visible = "v"
        case offset = "o"
        case rotation = "r"
        case scale = "sc"
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
    
    public let uuid: UUID
    
    public var name: String
    public var data: SpriteAssetElementData
    
    public var children: [SpriteAssetElement]
    
    public init(name: String) {
        uuid = UUID()
        self.name = name
        data = SpriteAssetElementData(visible: true, offset: CGPoint(), rotation: 0, scale: CGPoint(x: 1, y: 1), color: CGColor(gray: 1, alpha: 1), colorBlend: 0)
        children = []
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decode(UUID.self, forKey: .uuid)
        
        name = try container.decode(String.self, forKey: .name)
        
        let whiteColor = CGColor(gray: 1, alpha: 1)
        
        data = SpriteAssetElementData(visible: true, offset: CGPoint(), rotation: 0, scale: CGPoint(x: 1, y: 1), color: whiteColor, colorBlend: 0)
        data.visible = (try container.decodeIfPresent(Bool.self, forKey: .visible)) ?? true
        data.spriteLocator = try? container.decode(SpriteLocator.self, forKey: .sprite)
        data.offset = try container.decode(CGPoint.self, forKey: .offset)
        data.rotation = try container.decode(Float.self, forKey: .rotation)
        data.scale = (try container.decodeIfPresent(CGPoint.self, forKey: .scale)) ?? CGPoint(x: 1, y: 1)
        
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
            data.color = CGColor(colorSpace: CGColorSpace(name: colorSpaceName as CFString)!, components: components)!
            
            data.colorBlend = try container.decode(Float.self, forKey: .colorBlend)
        }
        else {
            data.color = whiteColor
            data.colorBlend = 0
        }
        
        setParentForChildren()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        
        try container.encode(name, forKey: .name)
        try container.encode(data.visible, forKey: .visible)
        if let spriteLocator = data.spriteLocator {
            try container.encode(spriteLocator, forKey: .sprite)
        }
        try container.encode(data.offset, forKey: .offset)
        try container.encode(data.rotation, forKey: .rotation)
        try container.encode(data.scale, forKey: .scale)
        
        if !children.isEmpty {
            var subContainer = container.nestedUnkeyedContainer(forKey: .children)
            for child in children {
                try subContainer.encode(child)
            }
        }
        
        let colorSpaceName = data.color.colorSpace!.name! as String
        var subContainer = container.nestedContainer(keyedBy: CGColorCodingKeys.self, forKey: .color)
        try subContainer.encode(colorSpaceName, forKey: .colorSpaceName)
        var componentsContainer = subContainer.nestedUnkeyedContainer(forKey: .components)
        for component in data.color.components! {
            try componentsContainer.encode(component)
        }
        
        try container.encode(data.colorBlend, forKey: .colorBlend)
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
    
    public func getElement(uuid: UUID) -> SpriteAssetElement? {
        if self.uuid == uuid {
            return self
        }
        else {
            for child in children {
                if let element = child.getElement(uuid: uuid) {
                    return element
                }
            }
        }
        return nil
    }
    
    public func getElementRelativeOrder(uuid: UUID) -> Int? {
        if self.uuid == uuid {
            return 0
        }
        else {
            for i in 0..<children.count {
                let child = children[i]
                if let order  = child.getElementRelativeOrder(uuid: uuid) {
                    return order + i + 1
                }
            }
        }
        return nil
    }
    
    public subscript(trackType: SpriteAssetAnimationTrackType) -> Any {
        switch trackType {
        case .visibility:
            return data.visible
        case .color:
            return data.color
        case .sprite:
            return data.spriteLocator?.description ?? ""
        case .xOffset:
            return data.offset.x
        case .yOffset:
            return data.offset.y
        case .xScale:
            return data.scale.x
        case .yScale:
            return data.scale.y
        case .rotation:
            return data.rotation
        case .colorBlendFactor:
            return data.colorBlend
        }
    }
    
}
