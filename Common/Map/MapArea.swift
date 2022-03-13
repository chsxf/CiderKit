//
//  MapArea.swift
//  CiderKit
//
//  Created by Christophe SAUVEUR on 26/03/2022.
//

import Foundation

struct MapArea: Equatable {
    
    var x: Int
    var y: Int
    
    var width: Int
    var height: Int
    
    var minX: Int { x }
    var maxX: Int { x + width }
    
    var minY: Int { y }
    var maxY: Int { y + height }
    
    var rect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
    
    init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    init(from rect: CGRect) {
        let integral = rect.integral
        self.init(x: Int(integral.minX), y: Int(integral.minY), width: Int(integral.width), height: Int(integral.height))
    }
    
    func contains(_ other: MapArea) -> Bool {
        return minX <= other.minX && maxX >= other.maxX && minY <= other.minY && maxY >= other.maxY
    }
    
    func intersects(_ other: MapArea) -> Bool {
        let overlapsOnX = (maxX > other.minX && minX < other.maxX)
        let overlapsOnY = (maxY > other.minY && minY < other.maxY)
        return overlapsOnX && overlapsOnY
    }
    
    func intersection(_ other: MapArea) -> MapArea? {
        var intersectionArea: MapArea? = nil
        
        if intersects(other) {
            let newX = max(x, other.x)
            let newY = max(y, other.y)
            let newWidth = min(maxX, other.maxX) - newX
            let newHeight = min(maxY, other.maxY) - newY
            intersectionArea = MapArea(x: newX, y: newY, width: newWidth, height: newHeight)
        }
        
        return intersectionArea
    }
    
}
