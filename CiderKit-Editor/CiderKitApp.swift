import Cocoa
import SwiftUI
import UniformTypeIdentifiers
import Combine
import CiderKit_Engine

private extension NSToolbarItem.Identifier {
    static let increaseElevation = NSToolbarItem.Identifier(rawValue: "increase_elevation")
    static let decreaseElevation = NSToolbarItem.Identifier(rawValue: "decrease_elevation")
    static let ambientLightSettings = NSToolbarItem.Identifier(rawValue: "ambientlight_settings")
    static let toggleLighting = NSToolbarItem.Identifier(rawValue: "toogle_lighting")
}

@main
class CiderKitApp: NSObject, NSApplicationDelegate, NSWindowDelegate, NSToolbarDelegate {

    public static let appName = "CiderKit Editor"
    
    private var window: NSWindow!
    private var gameView: EditorGameView!
    
    private var currentMapURL: URL? = nil
    
    private var mapDirtyFlagCancellable: AnyCancellable?
    private var selectionModelCancellable: AnyCancellable?
    
    private let allowedToolbarIdentifiers: [NSToolbarItem.Identifier] = [
        .increaseElevation, .decreaseElevation, .ambientLightSettings, .toggleLighting
    ]
    
    private let defaultToolbarIdentifiers: [NSToolbarItem.Identifier] = [
        .increaseElevation, .decreaseElevation, .ambientLightSettings, .toggleLighting
    ]
    
    private var definedToolbarItems: [NSToolbarItem.Identifier: NSToolbarItem] = [:]
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if saveCurrentMapIfModified() {
            return .terminateNow
        }
        return .terminateCancel
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return saveCurrentMapIfModified()
    }
    
    private func setup() -> Void {
        let windowRect = CGRect(x: 100, y: 100, width: 640, height: 360)
        window = NSWindow(contentRect: windowRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.delegate = self
        window.acceptsMouseMovedEvents = true
        gameView = EditorGameView(frame: windowRect)
        EditorGameViewRepresentable.gameView = gameView
        window.contentView = NSHostingView(rootView: EditorMainView())
        
        updateWindowTitle()
        observeMapDirtyFlag()
        observeSelectionModel()
    }
    
    private func setupMainMenu() -> Void {
        let mainMenu = NSMenu()
        
        let menuItemOne = NSMenuItem()
        menuItemOne.submenu = NSMenu(title: "menuItemOne")
        menuItemOne.submenu?.items = [
            NSMenuItem(title: "Quit \(Self.appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        ]
        
        let fileMenu = NSMenuItem()
        fileMenu.submenu = NSMenu(title: "File")
        fileMenu.submenu?.items = [
            NSMenuItem(title: "New Map", action: #selector(self.newMap), keyEquivalent: ""),
            NSMenuItem(title: "Load Map...", action: #selector(self.loadMap), keyEquivalent: ""),
            NSMenuItem(title: "Save Map", action: #selector(self.saveMap), keyEquivalent: ""),
            NSMenuItem(title: "Save Map As...", action: #selector(self.saveMapAs), keyEquivalent: "")
        ]
        
        let mapMenu = NSMenuItem()
        mapMenu.submenu = NSMenu(title: "Map")
        mapMenu.submenu?.items = [
            NSMenuItem(title: "Increase Elevation for Whole Map", action: #selector(self.increaseElevationForWholeMap), keyEquivalent: ""),
            NSMenuItem(title: "Decrease Elevation for Whole Map", action: #selector(self.decreaseElevationForWholeMap), keyEquivalent: "")
        ]
        
        mainMenu.items = [menuItemOne, fileMenu, mapMenu]
        NSApp.mainMenu = mainMenu
    }
    
    private func setupToolbar() -> Void {
        initToolbarItems()
        
        let toolbar = NSToolbar(identifier: "main")
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self
        window.toolbar = toolbar
    }
    
    private func initToolbarItems() -> Void {
        let increaseElevationItem = NSToolbarItem(itemIdentifier: .increaseElevation)
        increaseElevationItem.label = "Increase"
        increaseElevationItem.image = NSImage(named: "arrow_up")
        increaseElevationItem.action = #selector(self.increaseElevationForSelection)
        definedToolbarItems[.increaseElevation] = increaseElevationItem
        
        let decreaseElevationItem = NSToolbarItem(itemIdentifier: .decreaseElevation)
        decreaseElevationItem.label = "Decrease"
        decreaseElevationItem.image = NSImage(named: "arrow_down")
        decreaseElevationItem.action = #selector(self.decreaseElevationForSelection)
        definedToolbarItems[.decreaseElevation] = decreaseElevationItem
        
        let ambientLightSettingsItem = NSToolbarItem(itemIdentifier: .ambientLightSettings)
        ambientLightSettingsItem.label = "Ambient Light Settings"
        ambientLightSettingsItem.image = NSImage(named: "ambientlight_settings")
        ambientLightSettingsItem.action = #selector(self.selectAmbientLight)
        definedToolbarItems[.ambientLightSettings] = ambientLightSettingsItem
        
        let toggleLightingItem = NSToolbarItem(itemIdentifier: .toggleLighting)
        toggleLightingItem.label = "Toggle Lighting"
        toggleLightingItem.image = NSImage(named: "lighting_on")
        toggleLightingItem.action = #selector(self.toggleLighting)
        definedToolbarItems[.toggleLighting] = toggleLightingItem
    }
    
    private func openProjectManagerView() -> Void {
        let windowRect = CGRect(x: 0, y: 0, width: 640, height: 360)
        let pmWindow = NSWindow(contentRect: windowRect, styleMask: [.titled], backing: .buffered, defer: false)
        let pmView = ProjectManagerView(parentWindow: window, hostingWindow: pmWindow).environmentObject(ProjectManager.default)
        pmWindow.contentView = NSHostingView(rootView: pmView)
        
        window.beginSheet(pmWindow) { response in
            if response == .abort {
                NSApp.terminate(self)
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
        return allowedToolbarIdentifiers
    }
    
    private func observeMapDirtyFlag() {
        mapDirtyFlagCancellable = gameView.map.objectWillChange.sink {
            DispatchQueue.main.async {
                self.updateWindowTitle()
            }
        }
    }
    
    private func observeSelectionModel() {
        selectionModelCancellable = gameView.selectionModel.objectWillChange.sink {
            DispatchQueue.main.async {
                if let visibleItems = self.window.toolbar?.visibleItems {
                    for visibleItem in visibleItems {
                        if visibleItem.itemIdentifier == .increaseElevation || visibleItem.itemIdentifier == .decreaseElevation {
                            visibleItem.isEnabled = self.gameView.selectionModel.hasSelectedArea
                        }
                    }
                }
            }
        }
    }
    
    private func updateWindowTitle() {
        var title = "\(CiderKitApp.appName) - \(currentMapURL?.lastPathComponent ?? "Untitled")"
        if gameView.mutableMap.dirty {
            title += " *"
        }
        window.title = title
    }
    
    private func saveCurrentMapIfModified() -> Bool {
        var shouldSave = false
        if gameView.mutableMap.dirty {
            let alert = NSAlert()
            alert.messageText = "Would you like to save the current map?"
            alert.informativeText = "Confirmation"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            alert.addButton(withTitle: "Cancel")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                shouldSave = true
            case .alertSecondButtonReturn:
                shouldSave = false
                gameView.unloadMap()
                currentMapURL = nil
            default:
                return false
            }
        }
        return !shouldSave || saveCurrentMap()
    }
    
    private func saveCurrentMap(forceFileSelection: Bool = false) -> Bool {
        var selectedURL: URL? = currentMapURL
        if forceFileSelection {
            selectedURL = nil
        }
        if selectedURL == nil {
            let savePanel = NSSavePanel()
            savePanel.directoryURL = Project.current?.mapsDirectoryURL
            if let type = UTType("com.xhaleera.CiderKit.map") {
                savePanel.allowedContentTypes = [ type ]
            }
            let response = savePanel.runModal()
            if response == .OK {
                selectedURL = savePanel.url
            }
        }
        
        if let validURL = selectedURL {
            do {
                let mapDescription = gameView.map.toMapDescription()
                try EditorFunctions.save(mapDescription, to: validURL, prettyPrint: true)
                currentMapURL = validURL
                gameView.mutableMap.dirty = false
                return true
            }
            catch {
                let alert = NSAlert()
                alert.informativeText = "Error"
                alert.messageText = "Unable to save map to file \(validURL)"
                alert.addButton(withTitle: "OK")
                let _ = alert.runModal()
            }
        }
        return false
    }
    
    @objc
    private func newMap() {
        if saveCurrentMapIfModified() {
            gameView.unloadMap()
            currentMapURL = nil
            updateWindowTitle()
            observeMapDirtyFlag()
        }
    }
    
    @objc
    private func loadMap() {
        if saveCurrentMapIfModified() {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false
            openPanel.directoryURL = Project.current?.mapsDirectoryURL
            if let type = UTType("com.xhaleera.CiderKit.map") {
                openPanel.allowedContentTypes = [ type ]
            }
            let response = openPanel.runModal()
            if response == .OK {
                currentMapURL = openPanel.urls[0]
                gameView.loadMap(file: currentMapURL!)
                updateWindowTitle()
                observeMapDirtyFlag()
            }
        }
    }
    
    @objc
    private func saveMap() {
        let _ = saveCurrentMap()
    }
    
    @objc
    private func saveMapAs() {
        let _ = saveCurrentMap(forceFileSelection: true)
    }
    
    @objc
    private func increaseElevationForSelection() {
        gameView.increaseElevation(area: gameView.selectionModel.selectedArea)
    }
    
    @objc
    private func decreaseElevationForSelection() {
        gameView.decreaseElevation(area: gameView.selectionModel.selectedArea)
    }
    
    @objc
    private func increaseElevationForWholeMap() {
        gameView.increaseElevation(area: nil)
    }
    
    @objc
    private func decreaseElevationForWholeMap() {
        gameView.decreaseElevation(area: nil)
    }
    
    @objc
    private func toggleLighting() {
        gameView.lightingEnabled = !gameView.lightingEnabled
        definedToolbarItems[.toggleLighting]!.image = gameView.lightingEnabled ? NSImage(named: "lighting_on") : NSImage(named: "lighting_off")
    }
    
    @objc
    private func selectAmbientLight() {
        gameView.selectionModel.setSelectable(gameView.ambientLightEntity?.findSelectableComponent())
    }
    
    static func main() -> Void {
        NSApp = NSApplication.shared
        
        let delegate = CiderKitApp()
        NSApp.delegate = delegate

        try! Atlases.load(atlases: [
            "default_tile": AtlasLocator(url: CiderKitEngine.bundle.url(forResource: "Default Tile Atlas", withExtension: "ckatlas")!, bundle: CiderKitEngine.bundle),
            "grid": AtlasLocator(url: Bundle.main.url(forResource: "Grid Atlas", withExtension: "ckatlas")!, bundle: Bundle.main)
        ])

        delegate.setup()
        delegate.setupMainMenu()
        delegate.setupToolbar()
        
        delegate.window.makeKeyAndOrderFront(nil)
        delegate.window.toggleFullScreen(nil)
        
        delegate.openProjectManagerView()
        
        NSApp.run()
    }

}
