import CiderKit_Engine

protocol SpriteAssetDescriptionViewDelegate: AnyObject {
    
    func descriptionView(_ view: SpriteAssetDescriptionView, nameChanged newName: String)
    
}
