import AppKit

private extension NSToolbarItem.Identifier {
    static let tool = NSToolbarItem.Identifier(rawValue: "tool")
    static let addLight = NSToolbarItem.Identifier(rawValue: "addLight")
    static let ambientLightSettings = NSToolbarItem.Identifier(rawValue: "ambientlight_settings")
    static let toggleLighting = NSToolbarItem.Identifier(rawValue: "toogle_lighting")
    static let spriteAssetEditor = NSToolbarItem.Identifier(rawValue: "sprite_asset_editor")
}

final class MainToolbar: NSObject, NSToolbarDelegate {
    
    private let allowedToolbarIdentifiers: [NSToolbarItem.Identifier] = [
        .tool, .flexibleSpace, .addLight, .ambientLightSettings, .toggleLighting, .spriteAssetEditor
    ]
    
    private let defaultToolbarIdentifiers: [NSToolbarItem.Identifier] = [
        .tool, .flexibleSpace, .addLight, .ambientLightSettings, .toggleLighting, .spriteAssetEditor
    ]
    
    private weak var actionsManager: MainActionsManager? = nil
    private var definedToolbarItems: [NSToolbarItem.Identifier: NSToolbarItem] = [:]
    
    init(actionsManager: MainActionsManager, window: NSWindow) {
        self.actionsManager = actionsManager
        
        super.init()
        
        initToolbarItems()
        
        let toolbar = NSToolbar(identifier: "main")
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self
        window.toolbar = toolbar
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
        definedToolbarItems[.tool] = toolItemGroup
        
        let addLightItem = NSToolbarItem(itemIdentifier: .addLight)
        addLightItem.label = "Add Light"
        addLightItem.image = NSImage(systemSymbolName: "lightbulb.fill", accessibilityDescription: "Add Light")
        addLightItem.target = actionsManager
        addLightItem.action = #selector(MainActionsManager.addLight)
        definedToolbarItems[.addLight] = addLightItem
        
        let ambientLightSettingsItem = NSToolbarItem(itemIdentifier: .ambientLightSettings)
        ambientLightSettingsItem.label = "Ambient Light Settings"
        ambientLightSettingsItem.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Ambient Light Settings")
        ambientLightSettingsItem.target = actionsManager
        ambientLightSettingsItem.action = #selector(MainActionsManager.selectAmbientLight)
        definedToolbarItems[.ambientLightSettings] = ambientLightSettingsItem
        
        let toggleLightingItem = NSToolbarItem(itemIdentifier: .toggleLighting)
        toggleLightingItem.label = "Toggle Lighting"
        toggleLightingItem.image = NSImage(systemSymbolName: "lightbulb.circle.fill", accessibilityDescription: "Toggle Lighting")
        toggleLightingItem.target = actionsManager
        toggleLightingItem.action = #selector(MainActionsManager.toggleLighting)
        definedToolbarItems[.toggleLighting] = toggleLightingItem
        
        let spriteAssetEditorItem = NSToolbarItem(itemIdentifier: .spriteAssetEditor)
        spriteAssetEditorItem.label = "Sprite Asset Editor"
        spriteAssetEditorItem.image = NSImage(systemSymbolName: "photo.fill", accessibilityDescription: "Sprite Asset Editor")
        spriteAssetEditorItem.target = actionsManager
        spriteAssetEditorItem.action = #selector(MainActionsManager.openSpriteAssetEditor)
        definedToolbarItems[.spriteAssetEditor] = spriteAssetEditorItem
    }
    
}
