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
    
    init(withSelectedCell cell: GKEntity? = nil) {
        hoveredCell = nil
        selectedCell = cell
    }
    
}
