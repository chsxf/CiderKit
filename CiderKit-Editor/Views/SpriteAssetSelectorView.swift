import AppKit
import CiderKit_Engine

class SpriteAssetSelectorView: ItemSelectorView<SpriteAssetLocator, SpriteAssetDatabase> {
    
    override func getResult() -> SpriteAssetLocator? {
        guard let selectedGroup, let selectedItemKey else { return nil }
        let uuid = UUID(uuidString: selectedItemKey)!
        return SpriteAssetLocator(databaseKey: selectedGroup, assetUUID: uuid)
    }
    
    override class func generateOrderedGroupKeys() -> [String] {
        var keys = [String]()
        for entry in Project.current!.spriteAssetDatabases {
            if entry.key != SpriteAssetDatabase.defaultDatabaseId {
                keys.append(entry.key)
            }
        }
        return keys.sorted()
    }
    
    override class func getGroup(with key: String) -> SpriteAssetDatabase? {
        Project.current?.spriteAssetDatabase(forId: key)
    }
    
    override class func itemLabel(in group: SpriteAssetDatabase, with key: String) -> String? {
        group[key]?.name
    }
    
}
