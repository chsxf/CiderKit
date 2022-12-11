import AppKit
import CiderKit_Engine

class SpriteSelectorView: ItemSelectorView<SpriteLocator, Atlas> {
    
    override func getResult() -> SpriteLocator? {
        guard let selectedGroup, let selectedItem else { return nil }
        return SpriteLocator(key: selectedGroup, sprite: selectedItem)
    }
    
    override class func generateOrderedGroupKeys() -> [String] {
        var keys = [String]()
        for entry in Atlases.loadedAtlases {
            if !entry.value.editorOnly && !entry.value.isVariant && !entry.value.atlasSprites.isEmpty {
                keys.append(entry.key)
            }
        }
        return keys.sorted()
    }
    
    override class func getGroup(with key: String) -> Atlas? { Atlases[key] }
    
}
