import AppKit

private extension NSToolbarItem.Identifier {
    static let tool = NSToolbarItem.Identifier(rawValue: "tool")
    static let addLight = NSToolbarItem.Identifier(rawValue: "addLight")
    static let ambientLightSettings = NSToolbarItem.Identifier(rawValue: "ambientlight_settings")
    static let toggleLighting = NSToolbarItem.Identifier(rawValue: "toogle_lighting")
    static let spriteAssetEditor = NSToolbarItem.Identifier(rawValue: "sprite_asset_editor")
}

class MainToolbar: NSObject, NSToolbarDelegate {
    
    private let allowedToolbarIdentifiers: [NSToolbarItem.Identifier] = [
        .tool, .flexibleSpace, .addLight, .ambientLightSettings, .toggleLighting, .spriteAssetEditor
    ]
    
    private let defaultToolbarIdentifiers: [NSToolbarItem.Identifier] = [
        .tool, .flexibleSpace, .addLight, .ambientLightSettings, .toggleLighting, .spriteAssetEditor
    ]
    
    private weak var app: CiderKitApp? = nil
    private var definedToolbarItems: [NSToolbarItem.Identifier: NSToolbarItem] = [:]
    
    init(app: CiderKitApp, window: NSWindow) {
        self.app = app
        
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
        ], selectionMode: .selectOne, labels: ["Select", "Move", "Elevation"], target: app, action: #selector(CiderKitApp.switchTool))
        toolItemGroup.selectedIndex = 0
        definedToolbarItems[.tool] = toolItemGroup
        
        let addLightItem = NSToolbarItem(itemIdentifier: .addLight)
        addLightItem.label = "Add Light"
        addLightItem.image = NSImage(systemSymbolName: "lightbulb.fill", accessibilityDescription: "Add Light")
        addLightItem.action = #selector(CiderKitApp.addLight)
        definedToolbarItems[.addLight] = addLightItem
        
        let ambientLightSettingsItem = NSToolbarItem(itemIdentifier: .ambientLightSettings)
        ambientLightSettingsItem.label = "Ambient Light Settings"
        ambientLightSettingsItem.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Ambient Light Settings")
        ambientLightSettingsItem.action = #selector(CiderKitApp.selectAmbientLight)
        definedToolbarItems[.ambientLightSettings] = ambientLightSettingsItem
        
        let toggleLightingItem = NSToolbarItem(itemIdentifier: .toggleLighting)
        toggleLightingItem.label = "Toggle Lighting"
        toggleLightingItem.image = NSImage(systemSymbolName: "lightbulb.circle.fill", accessibilityDescription: "Toggle Lighting")
        toggleLightingItem.action = #selector(CiderKitApp.toggleLighting)
        definedToolbarItems[.toggleLighting] = toggleLightingItem
        
        let spriteAssetEditorItem = NSToolbarItem(itemIdentifier: .spriteAssetEditor)
        spriteAssetEditorItem.label = "Sprite Asset Editor"
        spriteAssetEditorItem.image = NSImage(systemSymbolName: "photo.fill", accessibilityDescription: "Sprite Asset Editor")
        spriteAssetEditorItem.action = #selector(CiderKitApp.openSpriteAssetEditor)
        definedToolbarItems[.spriteAssetEditor] = spriteAssetEditorItem
    }
    
}
