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

    var absoluteWorldOffset: WorldPosition {
        var result = worldOffset
        if let parentRef = parent.ref {
            result += parentRef.absoluteWorldOffset
        }
        return result
    }

    subscript(trackType: AssetAnimationTrackType) -> Any? {
        get {
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

        set(value) {
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

}
