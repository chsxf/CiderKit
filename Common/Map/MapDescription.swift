//
//  MapDescription.swift
//  SKTestIsoMap
//
//  Created by Christophe SAUVEUR on 12/10/2021.
//

import Foundation

struct MapDescription: Codable {
    var regions: [MapRegionDescription]
    
    init() {
        regions = []
    }
}

struct MapRegionDescription: Codable {
    private var x: Int
    private var y: Int
    
    private var width: Int
    private var height: Int
    
    var elevation: Int
    
    var area: MapArea { MapArea(x: x, y: y, width: width, height: height) }
    
    init(x: Int, y: Int, width: Int, height: Int, elevation: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.elevation = elevation
    }
    
    init(area: MapArea, elevation: Int) {
        self.init(x: area.minX, y: area.minY, width: area.width, height: area.height, elevation: elevation)
    }
    
}

#if CIDERKIT_EDITOR
extension MapRegionDescription {
    func merge(with other: MapRegionDescription) -> MapRegionDescription? {
        guard elevation == other.elevation else {
            return nil
        }
        
        if area.width == other.area.width && area.minX == other.area.minX
                    && (area.maxY == other.area.minY || other.area.maxY == area.minY) {
            return MapRegionDescription(
                x: area.minX,
                y: min(area.minY, other.area.minY),
                width: area.width,
                height: area.height + other.area.height,
                elevation: elevation
            )
        }
        else if area.height == other.area.height && area.minY == other.area.minY
                    && (area.maxX == other.area.minX || other.area.maxX == area.minX) {
            return MapRegionDescription(
                x: min(area.minX, other.area.minX),
                y: area.minY,
                width: area.width + other.area.width,
                height: area.height,
                elevation: elevation
            )
        }
        
        return nil
    }
}
#endif
