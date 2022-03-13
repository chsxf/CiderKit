//
//  SelectionModel.swift
//  CiderKit
//
//  Created by Christophe SAUVEUR on 13/03/2022.
//

import Foundation
import GameplayKit

class SelectionModel: ObservableObject {
    
    @Published var hoveredCell: GKEntity?
    @Published var selectedCell: GKEntity?
    
    var selectedArea: MapArea? {
        guard let mapCellComponent = selectedCell?.component(ofType: MapCellComponent.self) else {
            return nil
        }
        return MapArea(x: mapCellComponent.mapX, y: mapCellComponent.mapY, width: 1, height: 1)
    }
    
    init(withSelectedCell cell: GKEntity? = nil) {
        hoveredCell = nil
        selectedCell = cell
    }
    
}
