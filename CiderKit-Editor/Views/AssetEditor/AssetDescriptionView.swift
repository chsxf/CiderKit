import Foundation
import AppKit
import CiderKit_Engine
import SpriteKit

extension NSUserInterfaceItemIdentifier {
    
    static let assetElement = NSUserInterfaceItemIdentifier(rawValue: "assetElement")
    
}

final class AssetDescriptionView: NSView, NSOutlineViewDelegate, NSTextFieldDelegate, AssetElementViewDelegate, AssetDescriptionSceneViewDelegate, ContextButtonDelegate {
    
    private static let noSpriteMessage = "No asset selected"

    weak var descriptionViewDelegate: AssetDescriptionViewDelegate? = nil
    
    private var nameField: NSTextField? = nil
    
    public private(set) weak var selectedAssetElement: TransformAssetElement? = nil {
        didSet {
            if oldValue?.type != selectedAssetElement?.type {
                if let existingElementView = elementView {
                    var elementViewConstraints = [NSLayoutConstraint]()
                    for constraint in constraints {
                        if constraint.firstItem === existingElementView {
                            elementViewConstraints.append(constraint)
                        }
                    }
                    removeConstraints(elementViewConstraints)
                    
                    for subview in elementViewContainer.subviews {
                        subview.removeFromSuperview()
                    }
                }
                
                if subviews.contains(where: { $0 === elementViewContainer }) {
                    elementView = buildElementView(from: selectedAssetElement!, assetDescription: assetDescription!, container: elementViewContainer)
                }
            }

            if let selectedAssetElement {
                addButton?.contextMenu = buildAddElementMenu()
                skView?.showBoundingBox(for: selectedAssetElement)
            }
            
            elementView?.assetDescription = assetDescription
            elementView?.element = selectedAssetElement
        }
    }
    
    private let elementViewContainer: NSView
    
    private weak var elementView: TransformAssetElementView? = nil
    private weak var animationView: AssetAnimationView? = nil
    
    private var outlineDataSource: AssetDescriptionOutlineDataSource? = nil
    private var outline: NSOutlineView? = nil
    private weak var addButton: ContextButton? = nil
    private weak var removeButton: NSButton? = nil
    
    private weak var skView: AssetDescriptionSceneView? = nil
    
    private var lastKnownDescriptionSceneViewZoomFactor: Int = 1
    
    private var assetInstance: AssetInstance? = nil
    
    var assetDescription: AssetDescription? = nil {
        didSet {
            if oldValue != nil && assetDescription == nil {
                buildNoSelectionLabel()
                assetInstance = nil
            }
            else if let assetDescription {
                selectedAssetElement = assetDescription.rootElement
                assetInstance = AssetInstance(assetDescription: assetDescription, horizontallyFlipped: false)
                
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
        elementViewContainer = NSView()
        elementViewContainer.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    private func buildElementView(from element: TransformAssetElement, assetDescription: AssetDescription, container: NSView) -> TransformAssetElementView {
        let type = try! AssetElementViewTypeRegistry.get(named: element.type)
        let newElementView = type.init(assetDescription: assetDescription, element: element)
        newElementView.elementViewDelegate = self
        newElementView.animationControlDelegate = animationView
        
        container.addSubview(newElementView)
        
        addConstraints([
            NSLayoutConstraint(item: newElementView, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: newElementView, attribute: .right, relatedBy: .equal, toItem: container, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: newElementView, attribute: .left, relatedBy: .equal, toItem: container, attribute: .left, multiplier: 1, constant: 0)
        ])
        
        return newElementView
    }
    
    private func buildControls() {
        removeControls()
        
        let nameLabel = NSTextField(labelWithString: "Asset Name")
        let nameField = NSTextField(string: "")
        nameField.delegate = self
        self.nameField = nameField
        let nameRow = NSStackView(views: [nameLabel, nameField])
        nameRow.orientation = .horizontal
        addSubview(nameRow)
        
        let label = NSTextField(labelWithString: "Asset Hierarchy")
        
        outline = NSOutlineView()
        outline!.delegate = self
        let column = NSTableColumn(identifier: .assetElement)
        outline!.addTableColumn(column)
        outline!.outlineTableColumn = column
        outline!.allowsEmptySelection = false
        outline!.allowsMultipleSelection = false
        outline!.headerView = nil

        let scroll = NSScrollView()
        scroll.documentView = outline!
        scroll.borderType = .bezelBorder
        
        let addButton = ContextButton(systemSymbolName: "plus")
        addButton.contextMenu = buildAddElementMenu()
        self.addButton = addButton
        let removeButton = NSButton(systemSymbolName: "minus", target: self, action: #selector(Self.removeAssetElement))
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

        let skView = AssetDescriptionSceneView(assetInstance: assetInstance!)
        skView.descriptionSceneViewDelegate = self
        addSubview(skView)
        self.skView = skView
        
        addSubview(elementViewContainer)
        
        self.elementView = buildElementView(from: selectedAssetElement!, assetDescription: assetDescription!, container: elementViewContainer)
        
        let animationView = AssetAnimationView(assetDescription: assetDescription!)
        self.animationView = animationView
        addSubview(animationView)
        skView.animationControlDelegate = animationView
        elementView!.animationControlDelegate = animationView
        
        addConstraints([
            NSLayoutConstraint(item: nameRow, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: nameRow, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: nameRow, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: leftVStack, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200),
            NSLayoutConstraint(item: leftVStack, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: leftVStack, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 32),
            NSLayoutConstraint(item: leftVStack, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -308),
            
            NSLayoutConstraint(item: skView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 208),
            NSLayoutConstraint(item: skView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -308),
            NSLayoutConstraint(item: skView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 32),
            NSLayoutConstraint(item: skView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -308),
            
            NSLayoutConstraint(item: elementViewContainer, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300),
            NSLayoutConstraint(item: elementViewContainer, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: elementViewContainer, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 32),
            NSLayoutConstraint(item: elementViewContainer, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -308),
            
            NSLayoutConstraint(item: animationView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: animationView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: animationView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: animationView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)
        ])

        updateControls()
    }
    
    private func buildAddElementMenu() -> NSMenu {
        let menu = NSMenu()
        
        for registeredType in AssetElementTypeRegistry.allRegistered {
            let item = NSMenuItem(title: "Add \(registeredType.typeLabel)", target: self, action: #selector(Self.addElement(_:)), keyEquivalent: "")
            item.representedObject = registeredType
            menu.addItem(item)
        }
        
        return menu
    }
    
    private func updateControls() {
        nameField!.stringValue = assetDescription!.name
        
        outlineDataSource = AssetDescriptionOutlineDataSource(asset: assetDescription!)
        outline!.dataSource = outlineDataSource
        outline!.expandItem(nil, expandChildren: true)
        
        if let skView {
            skView.assetInstance = assetInstance!
            skView.updateZoom(lastKnownDescriptionSceneViewZoomFactor)
        }
        
        animationView?.assetDescription = assetDescription!
        
        assetInstance?.currentAnimationName.overriddenValue = animationView?.currentAnimationName
    }
    
    @objc
    private func addElement(_ sender: NSMenuItem) {
        guard
            let type = sender.representedObject as? TransformAssetElement.Type,
            let item = outline!.item(atRow: outline!.selectedRow) as? TransformAssetElement
        else { return }
        
        let newChild = type.init(name: "New \(type.typeLabel)")
        item.addChild(newChild)
        outline!.reloadItem(item, reloadChildren: true)
        outline!.expandItem(item)
        let row = outline!.row(forItem: newChild)
        outline!.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        
        try! assetInstance!.instantiateElement(element: newChild)
        
        skView?.showBoundingBox(for: newChild)
    }
    
    @objc
    private func removeAssetElement() {
        guard let item = outline!.item(atRow: outline!.selectedRow) as? TransformAssetElement, !item.isRoot else { return }
        
        let parent = item.parent
        item.removeFromParent()
        outline!.reloadItem(parent, reloadChildren: true)
        let row = outline!.row(forItem: parent)
        outline!.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        
        assetInstance!.remove(element: item)
        
        if let assetDescription {
            for (_, animation) in assetDescription.animations {
                animation.removeAnimationTracks(for: item.uuid)
            }
            animationView?.reloadCurrentAnimation()
        }
    }
    
    public func getCurrentAnimationKey(trackType: AssetAnimationTrackType, for elementUUID: UUID) -> AssetAnimationKey? {
        guard
            let animationView,
            let assetDescription,
            let animationName = animationView.currentAnimationName
        else {
            return nil
        }
        return assetDescription.getAnimationKey(trackType: trackType, for: elementUUID, in: animationName, at: animationView.currentAnimationFrame)
    }
    
    public func update(element: TransformAssetElement) {
        if let skView {
            skView.updateElement(element)
            skView.showBoundingBox(for: element)
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let element = item as! TransformAssetElement
        return NSTextField(labelWithString: element.name)
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? TransformAssetElement {
            removeButton?.isEnabled = !selectedItem.isRoot
            selectedAssetElement = selectedItem
        }
    }
    
    func elementView(_ view: TransformAssetElementView, assetWFootprintChanged footprint: Int) {
        if let assetDescription, let skView {
            assetDescription.footprint.x = UInt32(footprint)
            skView.setFootprintGrid(assetDescription.footprint)
        }
    }
    
    func elementView(_ view: TransformAssetElementView, assetHFootprintChanged footprint: Int) {
        if let assetDescription, let skView {
            assetDescription.footprint.y = UInt32(footprint)
            skView.setFootprintGrid(assetDescription.footprint)
        }
    }
    
    func elementView(_ view: TransformAssetElementView, nameChanged newName: String) {
        if let selectedItem = outline?.item(atRow: outline!.selectedRow) as? TransformAssetElement {
            if !selectedItem.isRoot {
                selectedItem.name = newName
                outline!.reloadItem(selectedItem, reloadChildren: false)
            }
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            descriptionViewDelegate?.descriptionView(self, nameChanged: textField.stringValue)
        }
    }
    
    func descriptionSceneView(_ view: AssetDescriptionSceneView, zoomUpdated newZoomFactor: Int) {
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
        else if animationView?.currentAnimationName == nil {
            menu.addItem(withTitle: "No selected animation", action: nil, keyEquivalent: "")
        }
        else {
            for child in assetDescription.rootElement.children {
                addElementMenu(child, parent: assetDescription.rootElement, menu: menu)
            }
        }
        
        return menu
    }
    
    private func addElementMenu(_ element: TransformAssetElement, parent: TransformAssetElement, menu: NSMenu) {
        let elementItem = NSMenuItem(title: element.name, action: nil, keyEquivalent: "")
        
        let elementMenu = NSMenu()
        if !element.children.isEmpty {
            for child in element.children {
                addElementMenu(child, parent: element, menu: elementMenu)
            }
            elementMenu.addItem(NSMenuItem.separator())
        }
        
        for track in element.eligibleTrackTypes {
            let menuItem = NSMenuItem(title: track.displayName, action: nil, keyEquivalent: "")
            let animationName = animationView!.currentAnimationName!
            if !assetDescription!.hasAnimationTrack(track, for: element.uuid, in: animationName) {
                menuItem.representedObject = AssetAnimationTrackIdentifier(elementUUID: element.uuid, type: track)
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
        if let identifier = sender.representedObject as? AssetAnimationTrackIdentifier {
            let animationName = animationView!.currentAnimationName!
            assetDescription!.animations[animationName]!.animationTracks[identifier] = AssetAnimationTrack(type: identifier.trackType)
            animationView!.reloadCurrentAnimation()
        }
    }
    
}
