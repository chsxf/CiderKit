import AppKit
import CiderKit_Engine

class ItemSelectorView<ResultType, GroupType: StringKeysProvider>: NSView, NSComboBoxDelegate, NSComboBoxDataSource, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    
    let orderedGroupKeys: [String]
    private(set) var orderedItems: [Dictionary<String, String>.Element]? = nil
    
    private let selectButton: NSButton
    private let collectionView: NSCollectionView
    
    private(set) var selectedGroup: String? = nil
    private(set) var selectedItemKey: String? = nil
    
    init() {
        selectButton = NSButton(title: "Select", target: nil, action: #selector(Self.confirmSelection))
        collectionView = NSCollectionView()
        
        orderedGroupKeys = Self.generateOrderedGroupKeys()
        
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
    
    func getResult() -> ResultType? { nil }
    
    class func generateOrderedGroupKeys() -> [String] { [] }
    
    class func getGroup(with key: String) -> GroupType? { nil }
    
    class func itemLabel(in group: GroupType, with key: String) -> String? { key }
    
    @objc
    private func confirmSelection() {
        window!.sheetParent!.endSheet(window!, returnCode: .OK)
    }
    
    @objc
    private func cancelSelection() {
        window!.sheetParent!.endSheet(window!, returnCode: .abort)
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        orderedGroupKeys.count
    }
    
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        orderedGroupKeys.first(where: { $0.contains(string) })
    }
    
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        orderedGroupKeys.firstIndex(of: string) ?? NSNotFound
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        orderedGroupKeys[index]
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let combobox = notification.object as! NSComboBox
        let groupKey = orderedGroupKeys[combobox.indexOfSelectedItem]
        
        if let group = Self.getGroup(with: groupKey) {
            selectedGroup = groupKey
            var items = [String:String]()
            group.keys.forEach { key in
                items[key] = Self.itemLabel(in: group, with: key)
            }
            orderedItems = items.sorted(by: { firstItem, secondItem in
                firstItem.value < secondItem.value
            })
        }
        else {
            selectedGroup = nil
            orderedItems = nil
        }
        
        collectionView.reloadData()
        selectButton.isEnabled = false
        selectedItemKey = nil
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        orderedItems?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .textViewItem, for: indexPath)
        if let orderedItems {
            item.textField?.stringValue = orderedItems[indexPath.item].value
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
            selectedItemKey = orderedItems?[selectedIndexPath.item].key
        }
        else {
            selectedItemKey = nil
        }
        selectButton.isEnabled = selectedItemKey != nil
    }
    
}
