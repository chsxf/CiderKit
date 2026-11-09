public typealias AssetElementBaseProperties = (
    uuid: UUID,
    name: String,
    visible: Bool,
    worldOffset: WorldPosition,
    horizontallyFlipped: Bool,
    children: [SendableMutableRef<any AssetElement>]
)

public protocol AssetElement: Sendable, Hashable, Codable {

    associatedtype InstanceType

    var parent: SendableMutableRef<any AssetElement?> { get }

    var uuid: UUID { get set }

    var name: String { get }
    var visible: Bool { get set }
    var worldOffset: WorldPosition { get set }
    var horizontallyFlipped: Bool { get }

    var children: [SendableMutableRef<any AssetElement>] { get set }

    var type: String { get }
    static var typeLabel: String { get }

    subscript(trackType: AssetAnimationTrackType) -> Any? { get set }

    init(name: String)
    init(from container: KeyedDecodingContainer<AssetElementCodingKeys>) throws

    @MainActor func instantiate() -> InstanceType

}

public extension AssetElement {

    var isRoot: Bool { parent.ref == nil }

    var absoluteWorldOffset: WorldPosition {
        var result = worldOffset
        if let parentRef = parent.ref {
            result += parentRef.absoluteWorldOffset
        }
        return result
    }

    var eligibleTrackTypes: [AssetAnimationTrackType] {
        [ .xWorldOffset, .yWorldOffset, .zWorldOffset, .visibility ]
    }

    var combinedTrackTypes: [AssetAnimationTrackType] {
        [ .xWorldOffset, .yWorldOffset, .zWorldOffset ]
    }

    subscript(trackType: AssetAnimationTrackType) -> Any? {
        get { get(baseTrackType: trackType) }
        set { set(baseTrackType: trackType, value: newValue) }
    }

    func get(baseTrackType trackType: AssetAnimationTrackType) -> Any? {
        switch trackType {
        case .visibility:
            return visible
        case .xWorldOffset:
            return worldOffset.x
        case .yWorldOffset:
            return worldOffset.y
        case .zWorldOffset:
            return worldOffset.z
        default:
            return nil
        }
    }

    mutating func set(baseTrackType trackType: AssetAnimationTrackType, value: Any?) {
        if let value {
            switch trackType {
            case .visibility:
                visible = value as! Bool
            case .xWorldOffset:
                if value is CGFloat {
                    worldOffset.x = Float(value as! CGFloat)
                }
                else if value is Float {
                    worldOffset.x = value as! Float
                }
            case .yWorldOffset:
                if value is CGFloat {
                    worldOffset.y = Float(value as! CGFloat)
                }
                else if value is Float {
                    worldOffset.y = value as! Float
                }
            case .zWorldOffset:
                if value is CGFloat {
                    worldOffset.z = Float(value as! CGFloat)
                }
                else if value is Float {
                    worldOffset.z = value as! Float
                }
            default:
                break
            }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AssetElementCodingKeys.self)
        try self.init(from: container)
    }

    mutating func setParentForChildren() {
        for child in children {
            child.ref.parent.ref = self
            child.ref.setParentForChildren()
        }
    }

    mutating func addChild(_ child: any AssetElement) {
        let childRef = SendableMutableRef(child)
        children.append(childRef)
        child.parent.ref = self
    }

    mutating func removeFromParent() {
        if parent.ref != nil {
            parent.ref!.children.removeAll { $0.ref.uuid == uuid }
        }
    }

    mutating func renewUUID() -> UUID {
        uuid = UUID()
        return uuid
    }

    func getElement(uuid: UUID) -> any AssetElement? {
        if self.uuid == uuid {
            return self
        }
        else {
            for child in children {
                if let element = child.ref.getElement(uuid: uuid) {
                    return element
                }
            }
        }
        return nil
    }

    func getElementRelativeOrder(uuid: UUID) -> Int? {
        if self.uuid == uuid {
            return 0
        }
        else {
            for i in 0..<children.count {
                let child = children[i]
                if let order  = child.ref.getElementRelativeOrder(uuid: uuid) {
                    return order + i + 1
                }
            }
        }
        return nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uuid == rhs.uuid
    }

    static func decodeBaseProperties(from container: KeyedDecodingContainer<AssetElementCodingKeys>) throws -> AssetElementBaseProperties {
        let uuid = try container.decode(UUID.self, forKey: .uuid)
        let name = try container.decode(String.self, forKey: .name)

        let visible = (try container.decodeIfPresent(Bool.self, forKey: .visible)) ?? true
        let worldOffset = try container.decode(WorldPosition.self, forKey: .worldOffset)
        let horizontallyFlipped = (try container.decodeIfPresent(Bool.self, forKey: .horizontallyFlipped)) ?? false

        var children = [SendableMutableRef<any AssetElement>]()
        if var childrenSubContainer = try? container.nestedUnkeyedContainer(forKey: .children) {
            while !childrenSubContainer.isAtEnd {
                let childContainer = try childrenSubContainer.nestedContainer(keyedBy: AssetElementCodingKeys.self)
                let childTypeName = try childContainer.decode(String.self, forKey: .type)
                let childType = try AssetElementTypeRegistry.get(named: childTypeName)
                let child = try childType.init(from: childContainer)
                let childRef = SendableMutableRef(child)
                children.append(childRef)
            }
        }

        return (uuid, name, visible, worldOffset, horizontallyFlipped, children)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AssetElementCodingKeys.self)
        try encode(to: &container)
    }

    func encode(to container: inout KeyedEncodingContainer<AssetElementCodingKeys>) throws {
        try container.encode(uuid, forKey: .uuid)

        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)

        try container.encode(visible, forKey: .visible)
        try container.encode(worldOffset, forKey: .worldOffset)
        try container.encode(horizontallyFlipped, forKey: .horizontallyFlipped)

        if !children.isEmpty {
            var subContainer = container.nestedUnkeyedContainer(forKey: .children)
            for child in children {
                try subContainer.encode(child.ref)
            }
        }
    }

}
