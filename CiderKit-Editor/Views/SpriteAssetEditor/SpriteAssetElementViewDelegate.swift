import CiderKit_Engine

protocol SpriteAssetElementViewDelegate: AnyObject {
    
    func elementView(_ view: SpriteAssetElementView, nameChanged newName: String)
    func elementView(_ view: SpriteAssetElementView, visibilityChanged visible: Bool)
    func elementView(_ view: SpriteAssetElementView, spriteChanged spriteLocator: SpriteLocator?)
    func elementView(_ view: SpriteAssetElementView, xOffsetChanged offset: Float)
    func elementView(_ view: SpriteAssetElementView, yOffsetChanged offset: Float)
    func elementView(_ view: SpriteAssetElementView, rotationChanged rotation: Float)
    func elementView(_ view: SpriteAssetElementView, xScaleChanged scale: Float)
    func elementView(_ view: SpriteAssetElementView, yScaleChanged scale: Float)
    func elementView(_ view: SpriteAssetElementView, colorChanged color: CGColor)
    func elementView(_ view: SpriteAssetElementView, colorBlendChanged colorBlend: Float)
    
}
