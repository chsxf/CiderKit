import AppKit
import CiderKit_Engine

class SpriteAssetDescriptionCollectionDataSource: NSObject, NSCollectionViewDataSource {
    
    private let database: SpriteAssetDatabase
    
    init(database: SpriteAssetDatabase) {
        self.database = database
        super.init()
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int { database.spriteAssets.count }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .textViewItem, for: indexPath)
        item.textField?.stringValue = database.spriteAssets[indexPath.item].name
        return item
    }
    
}
