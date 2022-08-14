import AppKit
import CiderKit_Engine

class SpriteAssetDatabaseView: NSStackView, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, SpriteAssetDescriptionViewDelegate {
    
    var database: SpriteAssetDatabase {
        didSet {
            spriteAssetDescriptionCollectionDataSource = SpriteAssetDescriptionCollectionDataSource(database: database)
            spriteAssetCollection.dataSource = spriteAssetDescriptionCollectionDataSource
            
            selectFirstItem()
            updateSelection()
        }
    }
    private var spriteAssetDescriptionCollectionDataSource: SpriteAssetDescriptionCollectionDataSource
    private var spriteAssetCollection: NSCollectionView!
    
    private let assetDescriptionView: SpriteAssetDescriptionView
    
    private var removeButton: NSButton!
    
    init(database: SpriteAssetDatabase) {
        self.database = database
        spriteAssetDescriptionCollectionDataSource = SpriteAssetDescriptionCollectionDataSource(database: database)
        
        assetDescriptionView = SpriteAssetDescriptionView()
        
        super.init(frame: NSZeroRect)
        orientation = .horizontal
        alignment = .top
        
        autoresizesSubviews = true
        
        assetDescriptionView.descriptionViewDelegate = self
        
        addArrangedSubview(buildAssetList())
        addArrangedSubview(assetDescriptionView)

        DispatchQueue.main.async {
            self.spriteAssetCollection.dataSource = self.spriteAssetDescriptionCollectionDataSource
            self.selectFirstItem()
            self.updateSelection()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func selectFirstItem() {
        if spriteAssetCollection.numberOfItems(inSection: 0) > 0 {
            spriteAssetCollection.selectItems(at: [IndexPath(item: 0, section: 0)], scrollPosition: .centeredVertically)
        }
    }
    
    private func buildAssetList() -> NSView {
        let label = NSTextField(labelWithString: "Sprite Assets")
        
        let layout = NSCollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        
        spriteAssetCollection = NSCollectionView()
        spriteAssetCollection.delegate = self
        spriteAssetCollection.collectionViewLayout = layout
        spriteAssetCollection.isSelectable = true
        spriteAssetCollection.allowsMultipleSelection = false
        spriteAssetCollection.allowsEmptySelection = false
        spriteAssetCollection.register(CollectionTextViewItem.self, forItemWithIdentifier: .textViewItem)

        let scroll = NSScrollView()
        scroll.documentView = spriteAssetCollection
        scroll.borderType = .bezelBorder
        
        let addButton = NSButton(title: "+", target: self, action: #selector(Self.addSpriteAsset))
        removeButton = NSButton(title: "-", target: self, action: #selector(Self.removeSpriteAsset))
        let buttonRow = NSStackView(views: [addButton, removeButton])
        buttonRow.orientation = .horizontal
        
        let stack = NSStackView(views: [label, scroll, buttonRow])
        stack.orientation = .vertical
        stack.alignment = .left
        stack.addConstraint(NSLayoutConstraint(item: scroll, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200))
        return stack
    }
    
    @objc
    private func addSpriteAsset() {
        spriteAssetCollection.deselectItems(at: spriteAssetCollection.selectionIndexPaths)
        let newIndex = database.spriteAssets.count
        var nameIndex = 1
        var name: String? = nil
        repeat {
            let potentialName = "New Sprite Asset \(nameIndex)"
            if !database.spriteAssets.contains(where: { $0.name == potentialName }) {
                name = potentialName
            }
            else {
                nameIndex += 1
            }
        }
        while name == nil
        database.spriteAssets.append(SpriteAssetDescription(name: name!))
        let indexPathSet: Set = [IndexPath(item: newIndex, section: 0)]
        spriteAssetCollection.insertItems(at: indexPathSet)
        spriteAssetCollection.selectItems(at: indexPathSet, scrollPosition: .nearestHorizontalEdge)
        updateSelection()
    }
    
    @objc
    private func removeSpriteAsset() {
        let selectedItems = spriteAssetCollection.selectionIndexPaths
        spriteAssetCollection.deselectItems(at: selectedItems)
        let indexPath = selectedItems.first!
        database.spriteAssets.remove(at: indexPath.item)
        spriteAssetCollection.deleteItems(at: [indexPath])
        if spriteAssetCollection.numberOfItems(inSection: 0) > 0 {
            spriteAssetCollection.selectItems(at: [IndexPath(item: 0, section: 0)], scrollPosition: .centeredVertically)
        }
        updateSelection()
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: collectionView.frame.size.width, height: 20)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        updateSelection()
    }
    
    func descriptionView(_ view: SpriteAssetDescriptionView, nameChanged newName: String) {
        if let selectedItem = spriteAssetCollection.selectionIndexPaths.first {
            let asset = database.spriteAssets[selectedItem.item]
            asset.name = newName
            spriteAssetCollection.reloadItems(at: [selectedItem])
            spriteAssetCollection.selectItems(at: [selectedItem], scrollPosition: .centeredVertically)
        }
    }
    
    private func updateSelection() {
        if let selectedItem = spriteAssetCollection.selectionIndexPaths.first {
            removeButton.isEnabled = true
            let asset = database.spriteAssets[selectedItem.item]
            assetDescriptionView.assetDescription = asset
        }
        else {
            removeButton.isEnabled = false
            assetDescriptionView.assetDescription = nil
        }
    }
    
}
