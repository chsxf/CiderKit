//
//  MapCellComponent.swift
//  CiderKit
//
//  Created by Christophe SAUVEUR on 12/03/2022.
//

import GameplayKit

class MapCellComponent: GKComponent
{
    private(set) weak var region: MapRegion?
    
    var mapX: Int
    var mapY: Int
    let elevation: Int?
    
    init(region: MapRegion?, mapX: Int, mapY: Int, elevation: Int?) {
        self.region = region
        self.mapX = mapX
        self.mapY = mapY
        self.elevation = elevation
        
        super.init()
    }
    
    convenience init(mapX: Int, mapY: Int) {
        self.init(region: nil, mapX: mapX, mapY: mapY, elevation: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func containsScenePosition(_ scenePosition: CGPoint) -> Bool {
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else {
            return false
        }
        
        var result = false
        
        let bounds = node.frame
        if bounds.contains(scenePosition) {
            let normalizedLocalX = (scenePosition.x - bounds.minX) / bounds.width
            let normalizedLocalY = (scenePosition.y - bounds.minY) / bounds.height
            
            result = true
            if (normalizedLocalX < 0.5 && (normalizedLocalY > 0.5 + normalizedLocalX || normalizedLocalY < 0.5 - normalizedLocalX))
                || (normalizedLocalX > 0.5 && (normalizedLocalY > 1.5 - normalizedLocalX || normalizedLocalY < normalizedLocalX - 0.5)) {
                result = false
            }
            
        }
        
        return result
    }
}
