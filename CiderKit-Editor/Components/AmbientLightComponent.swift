import GameplayKit
import SwiftUI
import CiderKit_Engine

class AmbientLightComponent: GKComponent, Selectable {
    
    let lightDescription: BaseLight
    
    var inspectableDescription: String { "Ambient Light"}
    
    private var bakedView: AnyView? = nil
    
    var inspectorView: AnyView {
        if let bakedView = bakedView {
            return bakedView
        }
        
        bakedView = AnyView(
            AmbientLightInspector()
                .environmentObject(lightDescription.delayed())
        )
        return bakedView!
    }
    
    fileprivate init(from lightDescription: BaseLight) {
        self.lightDescription = lightDescription
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func highlight() { }
    
    func demphasize() { }
    
    func contains(sceneCoordinates: CGPoint) -> Bool { false }
    
    func hovered() { }
    
    func departed() { }
    
    class func entity(from lightDescription: BaseLight) -> GKEntity {
        let newEntity = GKEntity();
        
        let ambientLightComponent = AmbientLightComponent(from: lightDescription)
        newEntity.addComponent(ambientLightComponent)
        
        return newEntity
    }
    
}
