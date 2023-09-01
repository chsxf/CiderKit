import AppKit
import CiderKit_Engine

class AssetSelectorView: ItemSelectorView<AssetLocator, AssetDatabase> {
    
    override func getResult() -> AssetLocator? {
        guard let selectedGroup, let selectedItemKey else { return nil }
        let uuid = UUID(uuidString: selectedItemKey)!
        return AssetLocator(databaseKey: selectedGroup, assetUUID: uuid)
    }
    
    override class func generateOrderedGroupKeys() -> [String] {
        var keys = [String]()
        for entry in Project.current!.assetDatabases {
            if entry.key != AssetDatabase.defaultDatabaseId {
                keys.append(entry.key)
            }
        }
        return keys.sorted()
    }
    
    override class func getGroup(with key: String) -> AssetDatabase? {
        Project.current?.assetDatabase(forId: key)
    }
    
    override class func itemLabel(in group: AssetDatabase, with key: String) -> String? {
        group[key]?.name
    }
    
}
