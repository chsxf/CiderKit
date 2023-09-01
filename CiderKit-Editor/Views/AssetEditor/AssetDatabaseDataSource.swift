import AppKit
import CiderKit_Engine

class AssetDatabaseDataSource: NSObject, NSComboBoxDataSource {
    
    private var databaseIds: [String]
    
    override init() {
        databaseIds = []
        for entry in Project.current!.assetDatabases {
            if entry.key != AssetDatabase.defaultDatabaseId {
                databaseIds.append(entry.value.id)
            }
        }
        
        super.init()
    }
    
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        for dbId in databaseIds {
            if dbId.contains(string) {
                return dbId
            }
        }
        return nil
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index >= 0 && index < databaseIds.count else {
            return nil
        }
        return databaseIds[index]
    }
    
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        for i in 0..<databaseIds.count {
            if databaseIds[i] == string {
                return i
            }
        }
        return NSNotFound
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        databaseIds.count
    }
    
}
