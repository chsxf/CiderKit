import Combine
import SpriteKit

public class AssetDescription: Identifiable, Codable, ObservableObject {
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case type
        case rootElement = "root"
        case animations
        case position = "pos"
        case footprint
    }
    
    public var id: String { uuid.description }
    
    public var databaseKey: String = ""
    public let uuid: UUID
    @Published public var name: String
    
    public var rootElement: TransformAssetElement
    
    public var footprint: SIMD2<UInt32>
    
    public var animations: [String: AssetAnimation] = [:]
    
    public var position: SIMD3<Float> { rootElement.offset }
    
    public var locator: AssetLocator { AssetLocator(databaseKey: databaseKey, assetUUID: uuid) }
    
    public init(name: String, databaseKey: String) {
        uuid = UUID()
        self.name = name
        self.databaseKey = databaseKey

        footprint = SIMD2<UInt32>(1, 1)
        
        rootElement = TransformAssetElement(name: "root")
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decode(UUID.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        footprint = (try container.decodeIfPresent(SIMD2<UInt32>.self, forKey: .footprint)) ?? SIMD2(1, 1)
        rootElement = try container.decode(TransformAssetElement.self, forKey: .rootElement)
        
        if container.contains(.animations) {
            let animationsContainer = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: .animations)
            for key in animationsContainer.allKeys {
                let animation = try animationsContainer.decode(AssetAnimation.self, forKey: key)
                animations[key.stringValue] = animation
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(footprint, forKey: .footprint)
        try container.encode(rootElement, forKey: .rootElement)

        var animationsContainer = container.nestedContainer(keyedBy: StringCodingKey.self, forKey: .animations)
        for (animationName, animation) in animations {
            try animationsContainer.encode(animation, forKey: StringCodingKey(stringValue: animationName)!)
        }
    }
    
    public func instantiate() -> AssetInstance {
        AssetInstance(assetDescription: self)
    }
    
    public func getElement(uuid: UUID) -> TransformAssetElement? { rootElement.getElement(uuid: uuid) }
    
    public func getElementOrder(uuid: UUID) -> Int? { rootElement.getElementRelativeOrder(uuid: uuid) }
    
    public func hasAnimation(named animationName: String) -> Bool { animations[animationName] != nil }
    
    public func hasAnimationTrack(_ type: AssetAnimationTrackType, for elementUUID: UUID, in animationName: String) -> Bool {
        animations[animationName]?.hasAnimationTrack(type, for: elementUUID) ?? false
    }
    
    public func getAnimationKey(trackType: AssetAnimationTrackType, for elementUUID: UUID, in animationName: String, at frame: UInt) -> AssetAnimationKey? {
        guard let animation = animations[animationName] else { return nil }
        
        let trackIdentifier = AssetAnimationTrackIdentifier(elementUUID: elementUUID, type: trackType)
        return animation.animationTracks[trackIdentifier]?.getKey(at: frame)
    }
    
    public func isElementAnimated(_ elementUUID: UUID, in animationName: String? = nil) -> Bool {
        if let animationName, let animation = animations[animationName] {
            for (identifier, track) in animation.animationTracks {
                if identifier.elementUUID == elementUUID && track.hasAnyKey {
                    return true
                }
            }
        }
        return false
    }
    
    public func getAnimationSnapshot(for elementUUID: UUID, in animationName: String?, at frame: UInt) -> AssetElementAnimationSnapshot {
        let element = getElement(uuid: elementUUID)!
        return getAnimationSnapshot(for: element, in: animationName, at: frame)
    }
    
    public func getAnimationSnapshot(for element: TransformAssetElement, in animationName: String?, at frame: UInt) -> AssetElementAnimationSnapshot {
        var animatedValues = [AssetAnimationTrackType: Any]()
        
        if let animationName, let animation = animations[animationName] {
            for (identifier, track) in animation.animationTracks {
                if track.hasAnyKey && identifier.elementUUID == element.uuid {
                    animatedValues[identifier.trackType] = track.getValue(at: frame)
                }
            }
        }
        
        return AssetElementAnimationSnapshot(frame: frame, element: element, animatedValues: animatedValues)
    }
    
    public final func canAddAsset(_ locator: AssetLocator) -> Bool {
        guard let addedAssetDescription = locator.assetDescription else { return false }
        
        if addedAssetDescription === self {
            return false
        }
        
        let referencedAssets = addedAssetDescription.getReferencedAssets(from: addedAssetDescription.rootElement)
        return referencedAssets.allSatisfy { self.canAddAsset($0) }
    }
    
    private func getReferencedAssets(from element: TransformAssetElement) -> Set<AssetLocator> {
        var references = Set<AssetLocator>()
        
        if let referenceElement = element as? ReferenceAssetElement, let reference = referenceElement.assetLocator {
            references.insert(reference)
        }
        
        for child in element.children {
            let childReferences = getReferencedAssets(from: child)
            references.formUnion(childReferences)
        }
        
        return references
    }
    
}
