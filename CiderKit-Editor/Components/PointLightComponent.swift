import Foundation
import GameplayKit
import CiderKit_Engine
import SwiftUI
import Combine

class PointLightComponent: GKComponent, Selectable, ObservableObject, EditableComponentDelegate {
    
    let lightDescription: PointLight
    
    var lightDescriptionChangeCancellable: AnyCancellable?
    
    let supportedToolModes: ToolMode = .move
    
    var inspectableDescription: String = "Point Light"
    
    private var bakedView: AnyView? = nil
    
    var inspectorView: AnyView {
        if let bakedView = bakedView {
            return bakedView
        }
        
        bakedView = AnyView(
            PointLightInspector()
                .environmentObject(lightDescription.delayed())
        )
        return bakedView!
    }
    
    fileprivate var lightNode: PointLightNode? { entity?.component(ofType: GKSKNodeComponent.self)?.node as? PointLightNode }
    
    fileprivate init(from lightDescription: PointLight) {
        self.lightDescription = lightDescription
        super.init()
        
        lightDescriptionChangeCancellable = self.lightDescription.objectWillChange.sink {
            if let editableComponent = self.entity?.component(ofType: EditableComponent.self) {
                editableComponent.invalidate()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func contains(sceneCoordinates: CGPoint) -> Bool {
        guard let lightNode = lightNode else {
            return false
        }
        let frame = lightNode.calculateAccumulatedFrame()
        return frame.contains(sceneCoordinates)
    }

    func hovered() {
        if let lightNode = lightNode {
            lightNode.hovered = true
        }
    }
    
    func departed() {
        if let lightNode = lightNode {
            lightNode.hovered = false
        }
    }
    
    func highlight() {
        if let lightNode = lightNode {
            lightNode.selected = true
        }
    }
    
    func demphasize() {
        if let lightNode = lightNode {
            lightNode.selected = false
        }
    }
    
    private class func computeScenePosition(from lightDescription: PointLight) -> CGPoint {
        let xyPosition = CGPoint(x: CGFloat(lightDescription.position.x), y: CGFloat(lightDescription.position.y))
        var scenePosition = Math.worldToScene(xyPosition, halfTileSize: CGSize(width: MapNode.halfWidth, height: MapNode.halfHeight))
        scenePosition.y += CGFloat(lightDescription.position.z) * CGFloat(MapNode.elevationHeight)
        return scenePosition
    }
    
    class func entity(from lightDescription: PointLight) -> GKEntity {
        let newEntity = GKEntity();
        
        let scenePosition = Self.computeScenePosition(from: lightDescription)
        
        let pointLight = PointLightNode()
        pointLight.position = scenePosition
        pointLight.enabled = lightDescription.enabled
        newEntity.addComponent(GKSKNodeComponent(node: pointLight))
        
        let pointLightComponent = PointLightComponent(from: lightDescription)
        newEntity.addComponent(pointLightComponent)
        
        newEntity.addComponent(EditableComponent(delegate: pointLightComponent))
        
        return newEntity
    }
    
    func validate() -> Bool {
        guard let pointLight = lightNode else {
            return false
        }
        
        pointLight.position = Self.computeScenePosition(from: lightDescription)
        pointLight.enabled = lightDescription.enabled
        
        return true
    }
    
    func dragBy(x: CGFloat, y: CGFloat, z: CGFloat) {
        lightDescription.position += vector_float3(x: Float(x), y: Float(y), z: Float(z))
        entity?.component(ofType: EditableComponent.self)?.invalidate()
    }
    
}
