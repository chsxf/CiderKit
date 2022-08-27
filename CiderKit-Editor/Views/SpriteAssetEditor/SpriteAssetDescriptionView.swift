import Foundation
import AppKit
import CiderKit_Engine
import SpriteKit

extension NSUserInterfaceItemIdentifier {
    
    static let spriteAssetElement = NSUserInterfaceItemIdentifier(rawValue: "spriteAssetElement")
    
}

class SpriteAssetDescriptionView: NSView, NSOutlineViewDelegate, NSTextFieldDelegate, SpriteAssetElementViewDelegate {
    
    private static let noSpriteMessage = "No sprite asset selected"

    weak var descriptionViewDelegate: SpriteAssetDescriptionViewDelegate? = nil
    
    private var nameField: NSTextField? = nil
    
    private weak var selectedAssetElement: SpriteAssetElement? = nil {
        didSet {
            elementView?.element = selectedAssetElement
        }
    }
    private var elementView: SpriteAssetElementView? = nil

    private var outlineDataSource: SpriteAssetDescriptionOutlineDataSource? = nil
    private var outline: NSOutlineView? = nil
    private weak var removeButton: NSButton? = nil
    
    private var skView: SKView? = nil
    private weak var scene: SpriteAssetDescriptionScene? = nil
    private var nodeByElement: [SpriteAssetElement: SKNode] = [:]
    private var zoomFactor: Int = 1
    
    private weak var zoomInButton: NSButton? = nil
    private weak var neutralZoomButton: NSButton? = nil
    private weak var zoomOutButton: NSButton? = nil
    
    var assetDescription: SpriteAssetDescription? = nil {
        didSet {
            if oldValue != nil && assetDescription == nil {
                buildNoSelectionLabel()
            }
            else if assetDescription != nil {
                selectedAssetElement = assetDescription!.rootElement
                
                if oldValue == nil {
                    buildControls()
                }
                else {
                    updateControls()
                }
            }
        }
    }
    
    init() {
        super.init(frame: NSZeroRect)

        buildNoSelectionLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func removeControls() {
        outlineDataSource = nil
        outline = nil
        nodeByElement.removeAll()
        scene = nil
        
        removeConstraints(constraints)
        
        let views = subviews
        for view in views {
            view.removeFromSuperview()
        }
    }
    
    private func buildNoSelectionLabel() {
        removeControls()
        
        let label = NSTextField(labelWithString: Self.noSpriteMessage)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        addConstraints([
            NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        ])
    }
    
    private func buildControls() {
        removeControls()
        
        let nameLabel = NSTextField(labelWithString: "Sprite Asset Name")
        let nameField = NSTextField(string: "")
        nameField.delegate = self
        self.nameField = nameField
        let nameRow = NSStackView(views: [nameLabel, nameField])
        nameRow.orientation = .horizontal
        addSubview(nameRow)
        
        let label = NSTextField(labelWithString: "Sprite Asset Hierarchy")
        
        outline = NSOutlineView()
        outline!.delegate = self
        let column = NSTableColumn(identifier: .spriteAssetElement)
        outline!.addTableColumn(column)
        outline!.outlineTableColumn = column
        outline!.allowsEmptySelection = false
        outline!.allowsMultipleSelection = false
        outline!.headerView = nil

        let scroll = NSScrollView()
        scroll.documentView = outline!
        scroll.borderType = .bezelBorder
        
        let addButton = NSButton(title: "+", target: self, action: #selector(Self.addSpriteElement))
        let removeButton = NSButton(title: "-", target: self, action: #selector(Self.removeSpriteElement))
        removeButton.isEnabled = false
        self.removeButton = removeButton
        let buttonRow = NSStackView(views: [addButton, removeButton])
        buttonRow.orientation = .horizontal

        let leftVStack = NSStackView(views: [label, scroll, buttonRow])
        leftVStack.orientation = .vertical
        leftVStack.alignment = .left
        addSubview(leftVStack)

        let skView = SKView()
        skView.translatesAutoresizingMaskIntoConstraints = false
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        addSubview(skView)
        self.skView = skView

        let zoomInButton = NSButton(title: "+", target: self, action: #selector(SpriteAssetDescriptionView.zoomIn))
        self.zoomInButton = zoomInButton
        let neutralZoomButton = NSButton(title: "100%", target: self, action: #selector(SpriteAssetDescriptionView.resetZoom))
        self.neutralZoomButton = neutralZoomButton
        let zoomOutButton = NSButton(title: "-", target: self, action: #selector(SpriteAssetDescriptionView.zoomOut))
        zoomOutButton.isEnabled = false
        self.zoomOutButton = zoomOutButton
        let zoomControlsStack = NSStackView(views: [zoomInButton, neutralZoomButton, zoomOutButton])
        zoomControlsStack.orientation = .horizontal
        skView.addSubview(zoomControlsStack)
        
        let elementView = SpriteAssetElementView(element: selectedAssetElement!)
        elementView.elementViewDelegate = self
        addSubview(elementView)
        self.elementView = elementView
        
        addConstraints([
            NSLayoutConstraint(item: nameRow, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: nameRow, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: nameRow, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: leftVStack, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200),
            NSLayoutConstraint(item: leftVStack, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: leftVStack, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 32),
            NSLayoutConstraint(item: leftVStack, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: elementView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200),
            NSLayoutConstraint(item: elementView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: elementView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 32),
            
            NSLayoutConstraint(item: skView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 208),
            NSLayoutConstraint(item: skView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -208),
            NSLayoutConstraint(item: skView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 32),
            NSLayoutConstraint(item: skView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: zoomControlsStack, attribute: .right, relatedBy: .equal, toItem: skView, attribute: .right, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: zoomControlsStack, attribute: .top, relatedBy: .equal, toItem: skView, attribute: .top, multiplier: 1, constant: 8)
        ])

        updateControls()
    }
    
    private func updateControls() {
        nameField!.stringValue = assetDescription!.name
        
        outlineDataSource = SpriteAssetDescriptionOutlineDataSource(asset: assetDescription!)
        outline!.dataSource = outlineDataSource
        outline!.expandItem(nil, expandChildren: true)
        
        let newScene = initScene()
        self.scene = newScene
        skView!.presentScene(newScene)
        updateZoom(zoomFactor)
    }
    
    @objc
    private func addSpriteElement() {
        if let item = outline!.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            let newChild = SpriteAssetElement(name: "New element")
            item.addChild(newChild)
            outline!.reloadItem(item, reloadChildren: true)
            outline!.expandItem(item)
            let row = outline!.row(forItem: newChild)
            outline!.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            
            let itemNode = nodeByElement[item]!
            let _ = createChildElementNode(element: newChild, parentNode: itemNode)
        }
    }
    
    @objc
    private func removeSpriteElement() {
        if let item = outline!.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            if item.isRoot {
                return
            }
            
            let parent = item.parent
            item.removeFromParent()
            outline!.reloadItem(parent, reloadChildren: true)
            let row = outline!.row(forItem: parent)
            outline!.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            
            let itemNode = nodeByElement[item]!
            itemNode.removeFromParent()
            removeNodeAndChildrenFromReferenceDictionary(topElement: item)
        }
    }
    
    @objc
    private func zoomIn() {
        updateZoom(min(16, zoomFactor + 1))
    }
    
    @objc
    private func resetZoom() {
        updateZoom(1)
    }
    
    @objc
    private func zoomOut() {
        updateZoom(max(1, zoomFactor - 1))
    }
    
    private func updateZoom(_ newZoomFactor: Int) {
        scene?.setZoomFactor(newZoomFactor)
        zoomInButton?.isEnabled = newZoomFactor < 16
        zoomOutButton?.isEnabled = newZoomFactor > 1
        neutralZoomButton?.title = "\(newZoomFactor * 100)%"
        zoomFactor = newZoomFactor
    }
    
    private func initScene() -> SpriteAssetDescriptionScene {
        let newScene = SpriteAssetDescriptionScene()
        
        let rootElement = assetDescription!.rootElement
        let rootNode = createChildElementNode(element: rootElement, parentNode: nil)
        newScene.addChild(rootNode)
        
        return newScene
    }
    
    private func createChildElementNode(element: SpriteAssetElement, parentNode: SKNode?) -> SKNode {
        let node: SKNode
        if let spriteLocator = element.spriteLocator {
            let texture = Atlases[spriteLocator]!
            let spriteNode = SKSpriteNode(texture: texture)
            node = spriteNode
            
            spriteNode.color = SKColor(cgColor: element.color)!
            spriteNode.colorBlendFactor = CGFloat(element.colorBlend)
        }
        else {
            node = SKNode()
        }
        node.name = element.name
        node.position = element.offset
        node.zRotation = CGFloat(element.rotation)
        parentNode?.addChild(node)
        nodeByElement[element] = node
        
        for child in element.children {
            let _ = createChildElementNode(element: child, parentNode: node)
        }
        
        return node
    }
    
    private func removeNodeAndChildrenFromReferenceDictionary(topElement: SpriteAssetElement) {
        nodeByElement.removeValue(forKey: topElement)
        for child in topElement.children {
            removeNodeAndChildrenFromReferenceDictionary(topElement: child)
        }
    }
    
    private func replaceNode(forItem item: SpriteAssetElement, with newNode: SKNode) {
        let node = nodeByElement[item]!
        let nodeIndex = node.parent!.children.firstIndex(where: { $0 === node})!
        node.parent!.insertChild(newNode, at: nodeIndex)
        node.removeFromParent()
        for childNode in node.children {
            childNode.removeFromParent()
            newNode.addChild(childNode)
        }
        newNode.name = item.name
        newNode.position = node.position
        nodeByElement[item] = newNode
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let element = item as! SpriteAssetElement
        return NSTextField(labelWithString: element.name)
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            removeButton?.isEnabled = !selectedItem.isRoot
            selectedAssetElement = selectedItem
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, nameChanged newName: String) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            if !selectedItem.isRoot {
                selectedItem.name = newName
                outline!.reloadItem(selectedItem, reloadChildren: false)
            }
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, spriteChanged spriteLocator: SpriteLocator?) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            if !selectedItem.isRoot {
                if selectedItem.spriteLocator == nil && spriteLocator != nil {
                    let newNode = SKSpriteNode(texture: Atlases[spriteLocator!]!)
                    replaceNode(forItem: selectedItem, with: newNode)
                }
                else if selectedItem.spriteLocator != nil && spriteLocator == nil {
                    replaceNode(forItem: selectedItem, with: SKNode())
                }
                else if selectedItem.spriteLocator != nil && spriteLocator != nil {
                    if selectedItem.spriteLocator != spriteLocator {
                        let node = nodeByElement[selectedItem]! as! SKSpriteNode
                        node.name = selectedItem.name
                        node.texture = Atlases[spriteLocator!]!
                    }
                }
                selectedItem.spriteLocator = spriteLocator
            }
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, offsetChanged offset: CGPoint) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            let node = nodeByElement[selectedItem]!
            node.position = offset
            selectedItem.offset = offset
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, rotationChanged rotation: Float) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            let degrees = Measurement(value: Double(rotation), unit: UnitAngle.degrees)
            let radians = degrees.converted(to: UnitAngle.radians)
            let node = nodeByElement[selectedItem]!
            node.zRotation = CGFloat(radians.value)
            selectedItem.rotation = rotation
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, colorChanged color: CGColor, colorBlend: Float) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            let node = nodeByElement[selectedItem] as! SKSpriteNode
            node.color = SKColor(cgColor: color)!
            node.colorBlendFactor = CGFloat(colorBlend)
            selectedItem.color = color
            selectedItem.colorBlend = colorBlend
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            descriptionViewDelegate?.descriptionView(self, nameChanged: textField.stringValue)
        }
    }
    
}
