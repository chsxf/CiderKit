import AppKit
import CiderKit_Engine

class AssetDatabaseView: NSStackView, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, AssetDescriptionViewDelegate {
    
    static private(set) var selectedDatabaseKey: String = ""
    
    var database: AssetDatabase {
        didSet {
            assetDescriptionCollectionDataSource = AssetDescriptionCollectionDataSource(database: database)
            assetCollection.dataSource = assetDescriptionCollectionDataSource
            
            selectFirstItem()
            updateSelection()
        }
    }
    private var assetDescriptionCollectionDataSource: AssetDescriptionCollectionDataSource
    private var assetCollection: NSCollectionView!
    
    private let assetDescriptionView: AssetDescriptionView
    
    private var removeButton: NSButton!
    
    init(database: AssetDatabase) {
        Self.selectedDatabaseKey = database.id
        self.database = database
        assetDescriptionCollectionDataSource = AssetDescriptionCollectionDataSource(database: database)
        
        assetDescriptionView = AssetDescriptionView()
        
        super.init(frame: NSZeroRect)
        orientation = .horizontal
        alignment = .top
        
        autoresizesSubviews = true
        
        assetDescriptionView.descriptionViewDelegate = self
        
        addArrangedSubview(buildAssetList())
        addArrangedSubview(assetDescriptionView)

        DispatchQueue.main.async {
            self.assetCollection.dataSource = self.assetDescriptionCollectionDataSource
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func selectFirstItem() {
        if assetCollection.numberOfItems(inSection: 0) > 0 {
            assetCollection.selectItems(at: [IndexPath(item: 0, section: 0)], scrollPosition: .centeredVertically)
        }
    }
    
    private func buildAssetList() -> NSView {
        let label = NSTextField(labelWithString: "Assets")
        
        let layout = NSCollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        
        assetCollection = NSCollectionView()
        assetCollection.delegate = self
        assetCollection.collectionViewLayout = layout
        assetCollection.isSelectable = true
        assetCollection.allowsMultipleSelection = false
        assetCollection.allowsEmptySelection = false
        assetCollection.register(CollectionTextViewItem.self, forItemWithIdentifier: .textViewItem)

        let scroll = NSScrollView()
        scroll.documentView = assetCollection
        scroll.borderType = .bezelBorder
        
        let addButton = NSButton(systemSymbolName: "plus", target: self, action: #selector(Self.addAsset))
        removeButton = NSButton(systemSymbolName: "minus", target: self, action: #selector(Self.removeAsset))
        let buttonRow = NSStackView(views: [addButton, removeButton])
        buttonRow.orientation = .horizontal
        
        let stack = NSStackView(views: [label, scroll, buttonRow])
        stack.orientation = .vertical
        stack.alignment = .left
        stack.addConstraint(NSLayoutConstraint(item: scroll, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200))
        return stack
    }
    
    @objc
    private func addAsset() {
        assetCollection.deselectItems(at: assetCollection.selectionIndexPaths)
        let newIndex = database.assets.count
        var nameIndex = 1
        var name: String? = nil
        repeat {
            let potentialName = "New Asset \(nameIndex)"
            if !database.assets.contains(where: { $0.name == potentialName }) {
                name = potentialName
            }
            else {
                nameIndex += 1
            }
        }
        while name == nil
                
        database.assets.append(AssetDescription(name: name!, databaseKey: Self.selectedDatabaseKey))
                
        let indexPathSet: Set = [IndexPath(item: newIndex, section: 0)]
        assetCollection.insertItems(at: indexPathSet)
        assetCollection.selectItems(at: indexPathSet, scrollPosition: .nearestHorizontalEdge)
        updateSelection()
    }
    
    @objc
    private func removeAsset() {
        let selectedItems = assetCollection.selectionIndexPaths
        assetCollection.deselectItems(at: selectedItems)
        let indexPath = selectedItems.first!
        database.assets.remove(at: indexPath.item)
        assetCollection.deleteItems(at: [indexPath])
        if assetCollection.numberOfItems(inSection: 0) > 0 {
            assetCollection.selectItems(at: [IndexPath(item: 0, section: 0)], scrollPosition: .centeredVertically)
        }
        updateSelection()
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: collectionView.frame.size.width, height: 20)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        updateSelection()
    }
    
    func descriptionView(_ view: AssetDescriptionView, nameChanged newName: String) {
        if let selectedItem = assetCollection.selectionIndexPaths.first {
            let asset = database.assets[selectedItem.item]
            asset.name = newName
            assetCollection.reloadItems(at: [selectedItem])
            assetCollection.selectItems(at: [selectedItem], scrollPosition: .centeredVertically)
        }
    }
    
    private func updateSelection() {
        if let selectedItem = assetCollection.selectionIndexPaths.first {
            removeButton.isEnabled = true
            let asset = database.assets[selectedItem.item]
            assetDescriptionView.assetDescription = asset
        }
        else {
            removeButton.isEnabled = false
            assetDescriptionView.assetDescription = nil
        }
    }
    
}
