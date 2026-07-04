import AppKit

extension NSToolbarItem.Identifier {
    static let tool = NSToolbarItem.Identifier(rawValue: "tool")
    static let addAsset = NSToolbarItem.Identifier(rawValue: "addAsset")
    static let addPointLight = NSToolbarItem.Identifier(rawValue: "addPointLight")
    static let addDirectionalLight = NSToolbarItem.Identifier(rawValue: "addDirectionalLight")
    static let ambientLightSettings = NSToolbarItem.Identifier(rawValue: "ambientlight_settings")
    static let toggleLighting = NSToolbarItem.Identifier(rawValue: "toogle_lighting")
    static let assetEditor = NSToolbarItem.Identifier(rawValue: "asset_editor")
}

final class MainToolbar: NSObject, NSToolbarDelegate {
    
    private let allowedToolbarIdentifiers: [NSToolbarItem.Identifier] = [
        .tool, .space, .addPointLight, .addDirectionalLight, .ambientLightSettings, .toggleLighting, .assetEditor
    ]
    
    private let defaultToolbarIdentifiers: [NSToolbarItem.Identifier] = [
        .tool, .space, .addAsset, .space, .addPointLight, .addDirectionalLight, .ambientLightSettings, .toggleLighting, .space, .assetEditor
    ]
    
    private weak var actionsManager: MainActionsManager? = nil
    private var definedToolbarItems: [NSToolbarItem.Identifier: NSToolbarItem] = [:]
    
    private var notificationTask: Task<Void, Never>? = nil
    
    init(actionsManager: MainActionsManager, window: NSWindow) {
        self.actionsManager = actionsManager
        
        super.init()
        
        initToolbarItems()
        
        let toolbar = NSToolbar(identifier: "main")
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self
        window.toolbar = toolbar
        
        notificationTask = setupNotifications()
    }
    
    deinit {
        notificationTask?.cancel()
    }
    
    private func setupNotifications() -> Task<Void, Never> {
        Task {
            await withThrowingTaskGroup { group in
                group.addTask {
                    for await hasSelection in NotificationCenter.default.notifications(named: .selectableUpdated).map({ $0.object != nil }) {
                        try Task.checkCancellation()
                        self.onSelectableUpdated(hasSelection: hasSelection)
                    }
                }
            }
        }
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        return definedToolbarItems[itemIdentifier]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return allowedToolbarIdentifiers
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return defaultToolbarIdentifiers
    }
    
    private func initToolbarItems() -> Void {
        let toolItemGroup = NSToolbarItemGroup(itemIdentifier: .tool, images: [
            NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: "Select")!,
            NSImage(systemSymbolName: "move.3d", accessibilityDescription: "Move")!,
            NSImage(systemSymbolName: "arrow.up.arrow.down", accessibilityDescription: "Elevation")!
        ], selectionMode: .selectOne, labels: ["Select", "Move", "Elevation"], target: actionsManager, action: #selector(MainActionsManager.switchTool))
        toolItemGroup.selectedIndex = 0
        toolItemGroup.toolTip = "Tool Mode"
        for i in 1...2 {
            toolItemGroup.subitems[i].isEnabled = false
        }
        definedToolbarItems[.tool] = toolItemGroup
        
        let addAssetItem = NSToolbarItem(itemIdentifier: .addAsset)
        addAssetItem.label = "Add Asset"
        addAssetItem.toolTip = addAssetItem.label
        addAssetItem.image = NSImage(systemSymbolName: "cube.fill", accessibilityDescription: "Add Asset")
        addAssetItem.target = actionsManager
        addAssetItem.action = #selector(MainActionsManager.addAsset)
        definedToolbarItems[.addAsset] = addAssetItem
        
        let addPointLightItem = NSToolbarItem(itemIdentifier: .addPointLight)
        addPointLightItem.label = "Add Point Light"
        addPointLightItem.toolTip = addPointLightItem.label
        addPointLightItem.image = NSImage(systemSymbolName: "lightbulb.fill", accessibilityDescription: "Add Point Light")
        addPointLightItem.target = actionsManager
        addPointLightItem.action = #selector(MainActionsManager.addPointLight)
        definedToolbarItems[.addPointLight] = addPointLightItem

        let addDirectionalLightItem = NSToolbarItem(itemIdentifier: .addDirectionalLight)
        addDirectionalLightItem.label = "Add Directional Light"
        addDirectionalLightItem.toolTip = addDirectionalLightItem.label
        addDirectionalLightItem.image = NSImage(systemSymbolName: "flashlight.on.fill", accessibilityDescription: "Add Directional Light")
        addDirectionalLightItem.target = actionsManager
        addDirectionalLightItem.action = #selector(MainActionsManager.addDirectionalLight)
        definedToolbarItems[.addDirectionalLight] = addDirectionalLightItem

        let ambientLightSettingsItem = NSToolbarItem(itemIdentifier: .ambientLightSettings)
        ambientLightSettingsItem.label = "Ambient Light Settings"
        ambientLightSettingsItem.toolTip = ambientLightSettingsItem.label
        ambientLightSettingsItem.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Ambient Light Settings")
        ambientLightSettingsItem.target = actionsManager
        ambientLightSettingsItem.action = #selector(MainActionsManager.selectAmbientLight)
        definedToolbarItems[.ambientLightSettings] = ambientLightSettingsItem
        
        let toggleLightingItem = NSToolbarItem(itemIdentifier: .toggleLighting)
        toggleLightingItem.label = "Toggle Lighting"
        toggleLightingItem.toolTip = toggleLightingItem.label
        toggleLightingItem.image = NSImage(systemSymbolName: "lightbulb.circle.fill", accessibilityDescription: "Toggle Lighting")
        toggleLightingItem.target = actionsManager
        toggleLightingItem.action = #selector(MainActionsManager.toggleLighting)
        definedToolbarItems[.toggleLighting] = toggleLightingItem
        
        let assetEditorItem = NSToolbarItem(itemIdentifier: .assetEditor)
        assetEditorItem.label = "Asset Editor"
        assetEditorItem.toolTip = assetEditorItem.label
        assetEditorItem.image = NSImage(systemSymbolName: "photo.fill", accessibilityDescription: "Asset Editor")
        assetEditorItem.target = actionsManager
        assetEditorItem.action = #selector(MainActionsManager.openAssetEditor)
        definedToolbarItems[.assetEditor] = assetEditorItem
    }
    
    private func onSelectableUpdated(hasSelection: Bool) {
        let toolGroup = definedToolbarItems[.tool] as! NSToolbarItemGroup
        let tools = toolGroup.subitems
        for i in 1...2 {
            tools[i].isEnabled = hasSelection
        }
    }
    
}
