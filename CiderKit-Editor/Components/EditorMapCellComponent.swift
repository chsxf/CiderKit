import Foundation
import CiderKit_Engine
import SpriteKit
import GameplayKit

class EditorMapCellComponent: MapCellComponent, Selectable, ObservableObject {
    
    private static var selectionShape: SKShapeNode!
    private static var hoveringShape: SKShapeNode!
    
    var inspectableDescription: String {
        position.elevation != nil ? "Map Cell" : "Map Cell (Empty)"
    }
    
    let supportedToolModes: ToolMode = .elevation
    
    var inspectorView: BaseInspectorView? {
        let view = InspectorViewFactory.getView(forClass: Self.self, generator: { MapCellInspector() })
        view.setObservableObject(self)
        return view
    }
    
    func highlight() {
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else {
            return
        }
        
        Self.selectionShape.isHidden = false
        Self.selectionShape.position = node.position
    }
    
    func deemphasize() {
        Self.selectionShape.isHidden = true
    }
    
    func hovered() {
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else {
            return
        }
        
        Self.hoveringShape.isHidden = false
        Self.hoveringShape.position = node.position
    }
    
    func departed() {
        Self.hoveringShape.isHidden = true
    }
    
    public static func initSelectionShapes(in container: SKNode) {
        var points: [CGPoint] = [
            CGPoint(x: -24, y: -12),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 24, y: -12),
            CGPoint(x: 0, y: -24),
            CGPoint(x: -24, y: -12)
        ]
        
        selectionShape = SKShapeNode(points: &points, count: points.count)
        selectionShape.strokeColor = NSColor.green
        selectionShape.lineWidth = 1
        selectionShape.zPosition = 5000
        selectionShape.isHidden = true
        container.addChild(selectionShape)
        
        hoveringShape = SKShapeNode(points: &points, count: points.count)
        hoveringShape.strokeShader = SKShader(fileNamed: "HoverShader")
        hoveringShape.strokeColor = NSColor.red
        hoveringShape.lineWidth = 1
        hoveringShape.zPosition = 5001
        hoveringShape.isHidden = true
        container.addChild(hoveringShape)
    }
    
}
