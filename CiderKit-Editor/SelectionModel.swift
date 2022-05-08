import Foundation
import GameplayKit
import CiderKit_Engine

class SelectionModel: ObservableObject {
    
    @Published private(set) var hoveredCell: GKEntity?
    @Published private(set) var selectedCell: GKEntity?
    
    var selectedArea: MapArea? {
        guard let mapCellComponent = selectedCell?.component(ofType: MapCellComponent.self) else {
            return nil
        }
        return MapArea(x: mapCellComponent.mapX, y: mapCellComponent.mapY, width: 1, height: 1)
    }
    
    var hasSelectedArea: Bool { selectedArea != nil }
    
    init(withSelectedCell cell: GKEntity? = nil) {
        hoveredCell = nil
        selectedCell = cell
    }
    
    func clear() {
        if selectedCell != nil {
            selectedCell = nil
        }
        if hoveredCell != nil {
            hoveredCell = nil
        }
    }
    
    func setHoveredCell(_ hoveredCell: GKEntity?) {
        if self.hoveredCell != hoveredCell {
            self.hoveredCell = hoveredCell
        }
    }
    
    func setSelectedCell(_ selectedCell: GKEntity?) {
        if self.selectedCell != selectedCell {
            self.selectedCell = selectedCell
        }
    }
    
}
