import Foundation

public struct MapDescription: Codable {
    var regions: [MapRegionDescription]
    var lighting: LightingDescription
    var renderers: [String:CellRendererDescription]
    
    init() {
        regions = []
        lighting = LightingDescription()
        renderers = [:]
    }
}

public struct MapRegionDescription: Codable {
    
    private enum MaterialOverrideContext: String {
        case ground = "g"
        case leftElevation = "l"
        case rightElevation = "r"
    }
    
    private var x: Int
    private var y: Int
    
    private var width: Int
    private var height: Int
    
    private var materialOverrides: [String: [CustomSettings?]]?
    
    var elevation: Int
    let renderer: String?
    
    public var spriteAssets: [SpriteAssetPlacement]? = nil
    
    public var area: MapArea { MapArea(x: x, y: y, width: width, height: height) }
    
    public init(x: Int, y: Int, width: Int, height: Int, elevation: Int, renderer: String?) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.elevation = elevation
        
        self.renderer = renderer
        materialOverrides = nil
        
        spriteAssets = []
    }
    
    public init(area: MapArea, elevation: Int, renderer: String?) {
        self.init(x: area.minX, y: area.minY, width: area.width, height: area.height, elevation: elevation, renderer: renderer)
    }
    
    init(byExporting area: MapArea, from other: MapRegionDescription) {
        self.init(area: area, elevation: other.elevation, renderer: other.renderer)
        importMaterialOverrides(from: other)
        importSpriteAssets(from: other)
    }
    
    private func getMaterialOverride(for context: MaterialOverrideContext, at index: Int) -> CustomSettings? {
        guard
            let container = materialOverrides?[context.rawValue],
            index >= 0,
            index < container.count
        else {
            return nil
        }
        return container[index]
    }
    
    func groundMaterialOverride(at index: Int) -> CustomSettings? {
        return getMaterialOverride(for: MaterialOverrideContext.ground, at: index)
    }
    
    func leftElevationMaterialOverride(at index: Int) -> CustomSettings? {
        return getMaterialOverride(for: MaterialOverrideContext.leftElevation, at: index)
    }
    
    func rightElevationMaterialOverride(at index: Int) -> CustomSettings? {
        return getMaterialOverride(for: MaterialOverrideContext.rightElevation, at: index)
    }
    
    public func merged(with other: MapRegionDescription) -> MapRegionDescription? {
        guard elevation == other.elevation, renderer == other.renderer else {
            return nil
        }
        
        var newDescription: MapRegionDescription? = nil
        
        if area.width == other.area.width && area.minX == other.area.minX
                    && (area.maxY == other.area.minY || other.area.maxY == area.minY) {
            newDescription = MapRegionDescription(
                x: area.minX,
                y: min(area.minY, other.area.minY),
                width: area.width,
                height: area.height + other.area.height,
                elevation: elevation,
                renderer: renderer
            )
        }
        else if area.height == other.area.height && area.minY == other.area.minY
                    && (area.maxX == other.area.minX || other.area.maxX == area.minX) {
            newDescription = MapRegionDescription(
                x: min(area.minX, other.area.minX),
                y: area.minY,
                width: area.width + other.area.width,
                height: area.height,
                elevation: elevation,
                renderer: renderer
            )
        }

        newDescription?.importMaterialOverrides(from: self)
        newDescription?.importSpriteAssets(from: self)
        newDescription?.importMaterialOverrides(from: other)
        newDescription?.importSpriteAssets(from: other)
    
        return newDescription
    }
    
    private mutating func importMaterialOverrides(from other: MapRegionDescription) {
        let relativeArea = other.area.relative(to: area)
        importMaterialOverrides(for: MaterialOverrideContext.ground, from: other, over: relativeArea)
        importMaterialOverrides(for: MaterialOverrideContext.leftElevation, from: other, over: relativeArea)
        importMaterialOverrides(for: MaterialOverrideContext.rightElevation, from: other, over: relativeArea)
    }
    
    private mutating func importMaterialOverrides(for context: MaterialOverrideContext, from other: MapRegionDescription, over relativeArea: MapArea) {
        let key = context.rawValue
        guard let otherMaterialOverrides = other.materialOverrides?[key] else {
            return
        }
        
        for x in 0..<area.width {
            for y in 0..<area.height {
                guard relativeArea.contains(x: x, y: y) else {
                    continue
                }
                
                let otherX = x - relativeArea.x
                let otherY = y - relativeArea.y
                let otherIndex = otherY * relativeArea.width + otherX
                guard otherIndex >= 0, otherIndex < otherMaterialOverrides.count, let otherOverride = otherMaterialOverrides[otherIndex] else {
                    continue
                }
                
                if materialOverrides == nil {
                    materialOverrides = [key: []]
                }
                if materialOverrides![key] == nil {
                    materialOverrides![key] = []
                }
                var materialOverridesArray = materialOverrides![key]!
                let localIndex = y * area.width + x
                if materialOverridesArray.count < localIndex {
                    materialOverridesArray.append(contentsOf: [CustomSettings?](repeating: nil, count: localIndex - materialOverridesArray.count))
                }
                materialOverridesArray.append(otherOverride)
                materialOverrides![key] = materialOverridesArray
            }
        }
    }
    
    private mutating func importSpriteAssets(from other: MapRegionDescription) {
        guard let otherSpriteAssets = other.spriteAssets else { return }
        
        let relativeToOtherArea = area.relative(to: other.area)
        let relativeToArea = other.area.relative(to: area)
        for spriteAsset in otherSpriteAssets {
            guard relativeToOtherArea.contains(x: spriteAsset.x, y: spriteAsset.y) else { continue }
        
            spriteAsset.x += relativeToArea.x
            spriteAsset.y += relativeToArea.y
            
            spriteAssets = spriteAssets ?? []
            spriteAssets!.append(spriteAsset)
        }
    }
    
}
