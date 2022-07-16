import AppKit
import CiderKit_Engine

class SpriteSelectorView: NSView, NSComboBoxDelegate, NSComboBoxDataSource, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    
    private let orderedAtlasKeys: [String]
    private var orderedSpriteNames: [String]? = nil
    
    private let selectButton: NSButton
    private let collectionView: NSCollectionView
    
    private var selectedAtlasKey: String? = nil
    private var selectedAtlas: Atlas? = nil
    private var selectedSpriteName: String? = nil
    
    var selectedSpriteLocator: SpriteLocator? {
        guard
            let selectedAtlasKey = selectedAtlasKey,
            let selectedSpriteName = selectedSpriteName
        else {
            return nil
        }
        return SpriteLocator(key: selectedAtlasKey, sprite: selectedSpriteName)
    }
    
    init() {
        selectButton = NSButton(title: "Select", target: nil, action: #selector(Self.confirmSelection))
        collectionView = NSCollectionView()
        
        var keys = [String]()
        for entry in Atlases.loadedAtlases {
            if !entry.value.editorOnly && !entry.value.isVariant && !entry.value.atlasSprites.isEmpty {
                keys.append(entry.key)
            }
        }
        orderedAtlasKeys = keys.sorted()
        
        super.init(frame: NSZeroRect)
        
        let atlasCombobox = NSComboBox()
        atlasCombobox.usesDataSource = true
        atlasCombobox.dataSource = self
        atlasCombobox.delegate = self
        
        let layout = NSCollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = layout
        collectionView.isSelectable = true
        collectionView.allowsEmptySelection = false
        collectionView.allowsMultipleSelection = false
        collectionView.register(CollectionTextViewItem.self, forItemWithIdentifier: .textViewItem)
        
        let scroll = NSScrollView()
        scroll.documentView = collectionView
        scroll.borderType = .bezelBorder
        
        selectButton.target = self
        selectButton.isEnabled = false
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(Self.cancelSelection))
        
        let buttonRow = NSStackView(views: [selectButton, cancelButton])
        buttonRow.orientation = .horizontal
        
        let mainStack = NSStackView(views: [atlasCombobox, scroll, buttonRow])
        mainStack.orientation = .vertical
        addSubview(mainStack)
        
        addConstraints([
            NSLayoutConstraint(item: mainStack, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15),
            NSLayoutConstraint(item: mainStack, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -15),
            NSLayoutConstraint(item: mainStack, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 15),
            NSLayoutConstraint(item: mainStack, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -15)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func confirmSelection() {
        window!.sheetParent!.endSheet(window!, returnCode: .OK)
    }
    
    @objc
    private func cancelSelection() {
        window!.sheetParent!.endSheet(window!, returnCode: .abort)
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        orderedAtlasKeys.count
    }
    
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        orderedAtlasKeys.first(where: { $0.contains(string) })
    }
    
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        orderedAtlasKeys.firstIndex(of: string) ?? NSNotFound
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        orderedAtlasKeys[index]
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let combobox = notification.object as! NSComboBox
        let atlasKey = orderedAtlasKeys[combobox.indexOfSelectedItem]
        
        if let atlas = Atlases[atlasKey] {
            selectedAtlasKey = atlasKey
            selectedAtlas = atlas
            orderedSpriteNames = atlas.atlasSprites.keys.sorted()
        }
        else {
            selectedAtlasKey = nil
            selectedAtlas = nil
            orderedSpriteNames = nil
        }
        
        collectionView.reloadData()
        selectButton.isEnabled = false
        selectedSpriteName = nil
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        orderedSpriteNames?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .textViewItem, for: indexPath)
        if let orderedSpriteKeys = orderedSpriteNames {
            item.textField?.stringValue = orderedSpriteKeys[indexPath.item]
        }
        else {
            item.textField?.stringValue = "NA"
        }
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        NSSize(width: collectionView.frame.size.width, height: 20)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let selectedIndexPath = indexPaths.first {
            selectedSpriteName = orderedSpriteNames?[selectedIndexPath.item]
        }
        else {
            selectedSpriteName = nil
        }
        selectButton.isEnabled = selectedSpriteName != nil
    }
    
}
