import Foundation
import GameplayKit
import CiderKit_Engine

extension Notification.Name {
    
    static let selectableUpdated = Notification.Name(rawValue: "selectableUpdated")
    
}

class SelectionModel: ObservableObject {
    
    @Published private(set) var hoverable: Hoverable?
    @Published private(set) var selectable: Selectable?
    
    var selectedMapArea: MapArea? {
        guard let mapCellComponent = selectable?.entity?.component(ofType: EditorMapCellComponent.self) else {
            return nil
        }
        return MapArea(x: mapCellComponent.mapX, y: mapCellComponent.mapY, width: 1, height: 1)
    }
    
    var hasSelectedMapArea: Bool { selectedMapArea != nil }
    
    init(selectable: Selectable? = nil) {
        hoverable = nil
        self.selectable = selectable
        self.selectable?.highlight()
    }
    
    func clear() {
        hoverable?.departed()
        hoverable = nil
        selectable?.deemphasize()
        selectable = nil
    }
    
    func setHoverable(_ hoverable: Hoverable?) {
        if self.hoverable !== hoverable {
            self.hoverable?.departed()
            self.hoverable = hoverable
            self.hoverable?.hovered()
        }
    }
    
    func setSelectable(_ selectable: Selectable?) {
        if self.selectable !== selectable {
            self.selectable?.deemphasize()
            self.selectable = selectable
            self.selectable?.highlight()
            NotificationCenter.default.post(name: .selectableUpdated, object: self.selectable)
        }
    }
    
}
