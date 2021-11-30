//
//  GameScene.swift
//  SKTestIsoMap
//
//  Created by Christophe SAUVEUR on 17/07/2021.
//

import SpriteKit
import GameplayKit

class GameScene : SKScene {
    
    var map: MapNode!
    
    init(size: CGSize, mapDescription: MapDescription) {
        super.init(size: size)
        
        map = MapNode(description: mapDescription)
        addChild(map)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getMapCenter() -> CGPoint {
        let frame = map.calculateAccumulatedFrame()
        return frame.origin.applying(CGAffineTransform(translationX: frame.size.width * 0.5, y: frame.size.height * 0.5))
    }
    
}
