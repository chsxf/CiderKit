import CiderKit_Engine

protocol SpriteAssetElementViewDelegate: AnyObject {
    
    func elementView(_ view: SpriteAssetElementView, nameChanged newName: String)
    func elementView(_ view: SpriteAssetElementView, spriteChanged spriteLocator: SpriteLocator?)
    func elementView(_ view: SpriteAssetElementView, offsetChanged offset: CGPoint)
    func elementView(_ view: SpriteAssetElementView, rotationChanged rotation: Float)
    func elementView(_ view: SpriteAssetElementView, scaleChanged scale: CGPoint)
    func elementView(_ view: SpriteAssetElementView, colorChanged color: CGColor, colorBlend: Float)
    
}
