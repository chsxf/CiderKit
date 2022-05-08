import Foundation

public struct MapDescription: Codable {
    var regions: [MapRegionDescription]
    
    init() {
        regions = []
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
    
    public var area: MapArea { MapArea(x: x, y: y, width: width, height: height) }
    
    public init(x: Int, y: Int, width: Int, height: Int, elevation: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.elevation = elevation
        
        materialOverrides = nil
    }
    
    public init(area: MapArea, elevation: Int) {
        self.init(x: area.minX, y: area.minY, width: area.width, height: area.height, elevation: elevation)
    }
    
    init(byExporting area: MapArea, from other: MapRegionDescription) {
        self.init(area: area, elevation: other.elevation)
        importMaterialOverrides(from: other)
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
    
    public func merging(with other: MapRegionDescription) -> MapRegionDescription? {
        guard elevation == other.elevation else {
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
                elevation: elevation
            )
        }
        else if area.height == other.area.height && area.minY == other.area.minY
                    && (area.maxX == other.area.minX || other.area.maxX == area.minX) {
            newDescription = MapRegionDescription(
                x: min(area.minX, other.area.minX),
                y: area.minY,
                width: area.width + other.area.width,
                height: area.height,
                elevation: elevation
            )
        }

        newDescription?.importMaterialOverrides(from: self)
        newDescription?.importMaterialOverrides(from: other)
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
        if let otherMaterialOverrides = other.materialOverrides?[key] {
            for x in 0..<area.width {
                for y in 0..<area.height {
                    let localIndex = y * area.width + x
                    if relativeArea.contains(x: x, y: y) {
                        let otherX = x - relativeArea.x
                        let otherY = y - relativeArea.y
                        let otherIndex = otherY * relativeArea.width + otherX
                        if otherIndex >= 0, otherIndex < otherMaterialOverrides.count, let otherOverride = otherMaterialOverrides[otherIndex] {
                            if materialOverrides == nil {
                                materialOverrides = [key: []]
                            }
                            if materialOverrides![key] == nil {
                                materialOverrides![key] = []
                            }
                            var materialOverridesArray = materialOverrides![key]!
                            if materialOverridesArray.count < localIndex {
                                materialOverridesArray.append(contentsOf: [CustomSettings?](repeating: nil, count: localIndex - materialOverridesArray.count))
                            }
                            materialOverridesArray.append(otherOverride)
                            materialOverrides![key] = materialOverridesArray
                        }
                    }
                }
            }
        }
    }
    
}
