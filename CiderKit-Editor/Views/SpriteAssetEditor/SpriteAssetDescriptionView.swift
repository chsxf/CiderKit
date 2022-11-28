import Foundation
import AppKit
import CiderKit_Engine
import SpriteKit

extension NSUserInterfaceItemIdentifier {
    
    static let spriteAssetElement = NSUserInterfaceItemIdentifier(rawValue: "spriteAssetElement")
    
}

final class SpriteAssetDescriptionView: NSView, NSOutlineViewDelegate, NSTextFieldDelegate, SpriteAssetElementViewDelegate, SpriteAssetDescriptionSceneViewDelegate, ContextButtonDelegate {
    
    private static let noSpriteMessage = "No sprite asset selected"

    weak var descriptionViewDelegate: SpriteAssetDescriptionViewDelegate? = nil
    
    private var nameField: NSTextField? = nil
    
    private weak var selectedAssetElement: SpriteAssetElement? = nil {
        didSet {
            elementView?.assetDescription = assetDescription
            elementView?.element = selectedAssetElement
        }
    }
    private weak var elementView: SpriteAssetElementView? = nil
    private weak var animationView: SpriteAssetAnimationView? = nil
    
    private var outlineDataSource: SpriteAssetDescriptionOutlineDataSource? = nil
    private var outline: NSOutlineView? = nil
    private weak var removeButton: NSButton? = nil
    
    private weak var skView: SpriteAssetDescriptionSceneView? = nil
    private weak var scene: SpriteAssetDescriptionScene? = nil
    
    private var lastKnownDescriptionSceneViewZoomFactor: Int = 1
    
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
            
            elementView?.assetDescription = assetDescription
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
        
        let addButton = NSButton(systemSymbolName: "plus", target: self, action: #selector(Self.addSpriteElement))
        let removeButton = NSButton(systemSymbolName: "minus", target: self, action: #selector(Self.removeSpriteElement))
        removeButton.isEnabled = false
        self.removeButton = removeButton
        let addAnimationTrackButton = ContextButton(systemSymbolName: "rectangle.stack.fill.badge.plus")
        addAnimationTrackButton.delegate = self
        let buttonRow = NSStackView(views: [addButton, removeButton, NSView(), addAnimationTrackButton])
        buttonRow.orientation = .horizontal
        buttonRow.distribution = .fill

        let leftVStack = NSStackView(views: [label, scroll, buttonRow])
        leftVStack.orientation = .vertical
        leftVStack.alignment = .left
        addSubview(leftVStack)

        let skView = SpriteAssetDescriptionSceneView(assetDescription: assetDescription!)
        skView.descriptionSceneViewDelegate = self
        addSubview(skView)
        self.skView = skView
        
        let elementView = SpriteAssetElementView(assetDescription: assetDescription!, element: selectedAssetElement!)
        elementView.elementViewDelegate = self
        addSubview(elementView)
        self.elementView = elementView
        
        let animationView = SpriteAssetAnimationView(assetDescription: assetDescription!)
        self.animationView = animationView
        addSubview(animationView)
        skView.animationControlDelegate = animationView
        elementView.animationControlDelegate = animationView
        
        addConstraints([
            NSLayoutConstraint(item: nameRow, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: nameRow, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: nameRow, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: leftVStack, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200),
            NSLayoutConstraint(item: leftVStack, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: leftVStack, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 32),
            NSLayoutConstraint(item: leftVStack, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -308),
            
            NSLayoutConstraint(item: elementView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200),
            NSLayoutConstraint(item: elementView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: elementView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 32),
            NSLayoutConstraint(item: elementView, attribute: .height, relatedBy: .lessThanOrEqual, toItem: self, attribute: .height, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: skView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 208),
            NSLayoutConstraint(item: skView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -208),
            NSLayoutConstraint(item: skView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 32),
            NSLayoutConstraint(item: skView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -308),
            
            NSLayoutConstraint(item: animationView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: animationView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: animationView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: animationView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)
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
        skView?.presentScene(newScene)
        skView?.updateZoom(lastKnownDescriptionSceneViewZoomFactor)
        
        animationView?.assetDescription = assetDescription!
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
            
            let _ = scene?.createChildElementNode(element: newChild, parentElement: item)
        }
    }
    
    @objc
    private func removeSpriteElement() {
        if let item = outline!.item(atRow: outline!.selectedRow) as? SpriteAssetElement, !item.isRoot {
            let parent = item.parent
            item.removeFromParent()
            outline!.reloadItem(parent, reloadChildren: true)
            let row = outline!.row(forItem: parent)
            outline!.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            
            scene?.removeNodes(from: item)
            
            if let assetDescription {
                for (_, state) in assetDescription.animationStates {
                    state.removeAnimationTracks(for: item.uuid)
                }
                animationView?.reloadCurrentState()
            }
        }
    }
    
    private func initScene() -> SpriteAssetDescriptionScene {
        let rootElement = assetDescription!.rootElement

        let newScene = SpriteAssetDescriptionScene()
        let _ = newScene.createChildElementNode(element: rootElement, parentElement: nil)
        return newScene
    }
    
    private func getCurrentAnimationKey(trackType: SpriteAssetAnimationTrackType, for elementUUID: UUID) -> SpriteAssetAnimationKey? {
        guard
            let animationView,
            let assetDescription,
            let stateName = animationView.currentAnimationState
        else {
            return nil
        }
        return assetDescription.getAnimationKey(trackType: trackType, for: elementUUID, in: stateName, at: animationView.currentAnimationFrame)
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
    
    func elementView(_ view: SpriteAssetElementView, visibilityChanged visible: Bool) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            scene?.setNodeVisibility(from: selectedItem, visible: visible)
            if let key = getCurrentAnimationKey(trackType: .visibility, for: selectedItem.uuid) {
                key.boolValue = visible
            }
            else {
                selectedItem.data.visible = visible
            }
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, spriteChanged spriteLocator: SpriteLocator?) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            if !selectedItem.isRoot {
                if selectedItem.data.spriteLocator == nil && spriteLocator != nil {
                    let newNode = SKSpriteNode(texture: Atlases[spriteLocator!]!)
                    newNode.color = SKColor(cgColor: selectedItem.data.color)!
                    newNode.colorBlendFactor = CGFloat(selectedItem.data.colorBlend)
                    scene?.replaceNode(for: selectedItem, with: newNode)
                }
                else if selectedItem.data.spriteLocator != nil && spriteLocator == nil {
                    scene?.replaceNode(for: selectedItem, with: SKNode())
                }
                else if selectedItem.data.spriteLocator != nil && spriteLocator != nil {
                    if selectedItem.data.spriteLocator != spriteLocator {
                        scene?.setSpriteTexture(from: selectedItem, texture: Atlases[spriteLocator!]!)
                    }
                }
                if let key = getCurrentAnimationKey(trackType: .sprite, for: selectedItem.uuid) {
                    key.stringValue = spriteLocator?.description ?? ""
                }
                else {
                    selectedItem.data.spriteLocator = spriteLocator
                }
            }
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, xOffsetChanged offset: Float) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            let cgOffset = CGFloat(offset)
            scene?.setNodeXPosition(from: selectedItem, x: cgOffset)
            if let key = getCurrentAnimationKey(trackType: .xOffset, for: selectedItem.uuid) {
                key.floatValue = offset
            }
            else {
                selectedItem.data.offset.x = cgOffset
            }
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, yOffsetChanged offset: Float) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            let cgOffset = CGFloat(offset)
            scene?.setNodeYPosition(from: selectedItem, y: cgOffset)
            if let key = getCurrentAnimationKey(trackType: .yOffset, for: selectedItem.uuid) {
                key.floatValue = offset
            }
            else {
                selectedItem.data.offset.y = cgOffset
            }
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, rotationChanged rotation: Float) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            scene?.setNodeRotation(from: selectedItem, rotationDegrees: rotation)
            if let key = getCurrentAnimationKey(trackType: .rotation, for: selectedItem.uuid) {
                key.floatValue = rotation
            }
            else {
                selectedItem.data.rotation = rotation
            }
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, xScaleChanged scale: Float) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            let cgScale = CGFloat(scale)
            scene?.setNodeXScale(from: selectedItem, scale: cgScale)
            if let key = getCurrentAnimationKey(trackType: .xScale, for: selectedItem.uuid) {
                key.floatValue = scale
            }
            else {
                selectedItem.data.scale.x = cgScale
            }
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, yScaleChanged scale: Float) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            let cgScale = CGFloat(scale)
            scene?.setNodeYScale(from: selectedItem, scale: cgScale)
            if let key = getCurrentAnimationKey(trackType: .yScale, for: selectedItem.uuid) {
                key.floatValue = scale
            }
            else {
                selectedItem.data.scale.y = cgScale
            }
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, colorChanged color: CGColor) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            scene?.setSpriteColor(from: selectedItem, color: color)
            if let key = getCurrentAnimationKey(trackType: .color, for: selectedItem.uuid) {
                key.colorValue = color
            }
            else {
                selectedItem.data.color = color
            }
        }
    }
    
    func elementView(_ view: SpriteAssetElementView, colorBlendChanged colorBlend: Float) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? SpriteAssetElement {
            scene?.setSpriteColorBlend(from: selectedItem, colorBlend: CGFloat(colorBlend))
            if let key = getCurrentAnimationKey(trackType: .colorBlendFactor, for: selectedItem.uuid) {
                key.floatValue = colorBlend
            }
            else {
                selectedItem.data.colorBlend = colorBlend
            }
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            descriptionViewDelegate?.descriptionView(self, nameChanged: textField.stringValue)
        }
    }
    
    func descriptionSceneView(_ view: SpriteAssetDescriptionSceneView, zoomUpdated newZoomFactor: Int) {
        lastKnownDescriptionSceneViewZoomFactor = newZoomFactor
    }
    
    func contextButtonRequestsMenu(_ button: ContextButton, for event: NSEvent) -> NSMenu? {
        guard
            event.type == .leftMouseDown,
            let assetDescription = assetDescription
        else { return nil }
        
        let menu = NSMenu()
        
        if assetDescription.rootElement.children.isEmpty {
            menu.addItem(withTitle: "No animatable element", action: nil, keyEquivalent: "")
        }
        else if animationView?.currentAnimationState == nil {
            menu.addItem(withTitle: "No selected animation state", action: nil, keyEquivalent: "")
        }
        else {
            for child in assetDescription.rootElement.children {
                addElementMenu(child, parent: assetDescription.rootElement, menu: menu)
            }
        }
        
        return menu
    }
    
    private func addElementMenu(_ element: SpriteAssetElement, parent: SpriteAssetElement, menu: NSMenu) {
        let elementItem = NSMenuItem(title: element.name, action: nil, keyEquivalent: "")
        
        let elementMenu = NSMenu()
        if !element.children.isEmpty {
            for child in element.children {
                addElementMenu(child, parent: element, menu: elementMenu)
            }
            elementMenu.addItem(NSMenuItem.separator())
        }
        
        for track in SpriteAssetAnimationTrackType.allCases {
            let menuItem = NSMenuItem(title: track.description, action: nil, keyEquivalent: "")
            let animationState = animationView!.currentAnimationState!
            if !assetDescription!.hasAnimationTrack(track, for: element.uuid, in: animationState) {
                menuItem.representedObject = SpriteAssetAnimationTrackIdentifier(elementUUID: element.uuid, type: track)
                menuItem.target = self
                menuItem.action = #selector(Self.addTrack(_:))
            }
            elementMenu.addItem(menuItem)
        }
        
        elementItem.submenu = elementMenu
        menu.addItem(elementItem)
    }
    
    @objc
    private func addTrack(_ sender: NSMenuItem) {
        if let identifier = sender.representedObject as? SpriteAssetAnimationTrackIdentifier {
            let animationState = animationView!.currentAnimationState!
            assetDescription!.animationStates[animationState]!.animationTracks[identifier] = SpriteAssetAnimationTrack(type: identifier.trackType)
            animationView!.reloadCurrentState()
        }
    }
    
}
