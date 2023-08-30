import CiderKit_Engine
import CoreGraphics

protocol SpriteAssetElementViewDelegate: AnyObject {
    
    func elementView(_ view: SpriteAssetElementView, assetXPositionChanged position: Float)
    func elementView(_ view: SpriteAssetElementView, assetYPositionChanged position: Float)
    func elementView(_ view: SpriteAssetElementView, assetZPositionChanged position: Float)
    func elementView(_ view: SpriteAssetElementView, assetXSizeChanged size: Float)
    func elementView(_ view: SpriteAssetElementView, assetYSizeChanged size: Float)
    func elementView(_ view: SpriteAssetElementView, assetZSizeChanged size: Float)
    func elementView(_ view: SpriteAssetElementView, assetWFootprintChanged footprint: Int)
    func elementView(_ view: SpriteAssetElementView, assetHFootprintChanged footprint: Int)
    
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
