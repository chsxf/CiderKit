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
