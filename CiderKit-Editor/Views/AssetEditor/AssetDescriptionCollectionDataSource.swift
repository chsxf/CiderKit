import AppKit
import CiderKit_Engine

class AssetDescriptionCollectionDataSource: NSObject, NSCollectionViewDataSource {
    
    private let database: AssetDatabase
    
    init(database: AssetDatabase) {
        self.database = database
        super.init()
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int { database.assets.count }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .textViewItem, for: indexPath)
        item.textField?.stringValue = database.assets[indexPath.item].name
        return item
    }
    
}
