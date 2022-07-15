import Foundation
import GameplayKit
import CiderKit_Engine

class SelectionModel: ObservableObject {
    
    @Published private(set) var hoverable: Hoverable?
    @Published private(set) var selectable: Selectable?
    
    let selectableUpdatedEvent = Event<Selectable>()
    
    var selectedArea: MapArea? {
        guard let mapCellComponent = selectable?.entity?.component(ofType: EditorMapCellComponent.self) else {
            return nil
        }
        return MapArea(x: mapCellComponent.mapX, y: mapCellComponent.mapY, width: 1, height: 1)
    }
    
    var hasSelectedArea: Bool { selectedArea != nil }
    
    init(selectable: Selectable? = nil) {
        hoverable = nil
        self.selectable = selectable
        self.selectable?.highlight()
    }
    
    func clear() {
        hoverable?.departed()
        hoverable = nil
        selectable?.demphasize()
        selectable = nil
    }
    
    func setHoverable(_ hoverable: Hoverable?) {
        self.hoverable?.departed()
        self.hoverable = hoverable
        self.hoverable?.hovered()
    }
    
    func setSelectable(_ selectable: Selectable?) {
        self.selectable?.demphasize()
        self.selectable = selectable
        self.selectable?.highlight()
        if let validSelectable = self.selectable {
            selectableUpdatedEvent.raise(validSelectable)
        }
    }
    
}
