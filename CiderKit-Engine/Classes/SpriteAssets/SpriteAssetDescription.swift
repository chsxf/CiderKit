import Combine
import SpriteKit

public struct SpriteAssetElementAnimationData {
    public var elementData: SpriteAssetElementData
    public var animatedTracks: [SpriteAssetAnimationTrackType:Bool]
 
    public func isKeyValue(for trackType: SpriteAssetAnimationTrackType) -> Bool { animatedTracks[trackType] ?? true }
}

public class SpriteAssetDescription: Identifiable, Codable, ObservableObject {
    
    enum CodingKeys: String, CodingKey {
        case uuid = "uuid"
        case name = "name"
        case type = "type"
        case rootElement = "root"
        case animationStates = "states"
    }
    
    struct StateCodingKey: CodingKey {
        var stringValue: String = ""
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? = nil
        
        init?(intValue: Int) {
            self.intValue = intValue
        }
    }
    
    public var id: String { uuid.description }
    
    let uuid: UUID
    @Published public var name: String
    
    public let type: SpriteAssetDescriptionType
    public var rootElement: SpriteAssetElement
    
    public var animationStates: [String: SpriteAssetAnimationState] = [:]
    
    public init(name: String, type: SpriteAssetDescriptionType = .hierarchical) {
        uuid = UUID()
        self.name = name
        self.type = type
        
        rootElement = SpriteAssetElement(name: "root")
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decode(UUID.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        type = (try container.decodeIfPresent(SpriteAssetDescriptionType.self, forKey: .type)) ?? .hierarchical
        rootElement = try container.decode(SpriteAssetElement.self, forKey: .rootElement)
        
        if container.contains(.animationStates) {
            let statesContainer = try container.nestedContainer(keyedBy: StateCodingKey.self, forKey: .animationStates)
            for key in statesContainer.allKeys {
                let state = try statesContainer.decode(SpriteAssetAnimationState.self, forKey: key)
                animationStates[key.stringValue] = state
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(rootElement, forKey: .rootElement)
        
        var statesContainer = container.nestedContainer(keyedBy: StateCodingKey.self, forKey: .animationStates)
        for (stateName, state) in animationStates {
            try statesContainer.encode(state, forKey: StateCodingKey(stringValue: stateName)!)
        }
    }
    
    public func getElement(uuid: UUID) -> SpriteAssetElement? { rootElement.getElement(uuid: uuid) }
    
    public func getElementOrder(uuid: UUID) -> Int? { rootElement.getElementRelativeOrder(uuid: uuid) }
    
    public func hasAnimationState(named stateName: String) -> Bool { animationStates[stateName] != nil }
    
    public func hasAnimationTrack(_ type: SpriteAssetAnimationTrackType, for elementUUID: UUID, in stateName: String) -> Bool {
        animationStates[stateName]?.hasAnimationTrack(type, for: elementUUID) ?? false
    }
    
    public func getAnimationKey(trackType: SpriteAssetAnimationTrackType, for elementUUID: UUID, in stateName: String, at frame: Int) -> SpriteAssetAnimationKey? {
        guard let animationState = animationStates[stateName] else { return nil }
        
        let trackIdentifier = SpriteAssetAnimationTrackIdentifier(elementUUID: elementUUID, type: trackType)
        return animationState.animationTracks[trackIdentifier]?.getKey(at: frame)
    }
    
    public func isElementAnimated(_ elementUUID: UUID, in stateName: String? = nil) -> Bool {
        if let stateName, let animationState = animationStates[stateName] {
            for (identifier, track) in animationState.animationTracks {
                if identifier.elementUUID == elementUUID && track.hasAnyKey {
                    return true
                }
            }
        }
        return false
    }
    
    public func getAnimationData(for elementUUID: UUID, in stateName: String? = nil, at frame: Int = 0) -> SpriteAssetElementAnimationData {
        let element = getElement(uuid: elementUUID)!
        return getAnimationData(for: element, in: stateName, at: frame)
    }
    
    public func getAnimationData(for element: SpriteAssetElement, in stateName: String? = nil, at frame: Int = 0) -> SpriteAssetElementAnimationData {
        if let stateName, let animationState = animationStates[stateName] {
            var data = element.data
            var animated = [SpriteAssetAnimationTrackType:Bool]()
            for (identifier, track) in animationState.animationTracks {
                if track.hasAnyKey && identifier.elementUUID == element.uuid {
                    animated[identifier.trackType] = track.hasKey(at: frame)
                    data.setValue(track.getValue(at: frame), for: identifier.trackType)
                }
            }
            return SpriteAssetElementAnimationData(elementData: data, animatedTracks: animated)
        }
        else {
            return SpriteAssetElementAnimationData(elementData: element.data, animatedTracks: [:])
        }
    }
    
    public func getSKActionsByElement(in stateName: String) -> [SpriteAssetElement:SKAction]? {
        guard let animationData = animationStates[stateName] else { return nil }

        var maxDuration: TimeInterval = 0
        var elements = Set<SpriteAssetElement>()
        for (identifier, track) in animationData.animationTracks {
            if track.hasAnyKey {
                elements.insert(getElement(uuid: identifier.elementUUID)!)
                if track.duration > maxDuration {
                    maxDuration = track.duration
                }
            }
        }
        
        var result = [SpriteAssetElement:SKAction]()
        for element in elements {
            if let elementActions = getSKAction(for: element, in: stateName, with: maxDuration) {
                result[element] = elementActions
            }
        }
        return result.isEmpty ? nil : result
    }
    
    public func getSKAction(for element: SpriteAssetElement, in stateName: String, with expectedDuration: TimeInterval) -> SKAction? {
        guard let animationState = animationStates[stateName] else { return nil }

        var actions = [SKAction]()
        for (identifier, track) in animationState.animationTracks {
            if identifier.elementUUID == element.uuid {
                if let trackAction = track.toSKAction(with: expectedDuration) {
                    actions.append(trackAction)
                }
            }
        }
        
        return actions.isEmpty ? nil : SKAction.group(actions)
    }
    
}
