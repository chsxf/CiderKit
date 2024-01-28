import AppKit
import UniformTypeIdentifiers
import SpriteKit
import CiderKit_Engine

final class MainActionsManager : NSObject, NSToolbarItemValidation {

    private weak var app: CiderKitApp? = nil
    private weak var gameView: EditorGameView? = nil
    
    private(set) var currentMapURL: URL? = nil
    
    init(app: CiderKitApp, gameView: EditorGameView) {
        self.app = app
        self.gameView = gameView
    }
    
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if item.itemIdentifier == .addAsset {
            guard
                let selectedArea = gameView?.selectionModel.selectedMapArea,
                gameView?.map.hasCell(forX: selectedArea.x, y: selectedArea.y) ?? false
            else {
                return false
            }
        }
        return true
    }
    
    @objc
    func switchTool(_ sender: NSToolbarItemGroup) {
        let toolMode = ToolMode(rawValue: 1 << sender.selectedIndex)
        gameView?.selectionManager?.currentToolMode = toolMode
    }
    
    @objc
    func addAsset() {
        let windowRect: CGRect = CGRect(x: 0, y: 0, width: 400, height: 600)

        let window = NSWindow(contentRect: windowRect, styleMask: [.resizable, .titled], backing: .buffered, defer: false)
        let selectorView = AssetSelectorView()
        window.contentView = selectorView

        app!.window.beginSheet(window) { responseCode in
            if responseCode == .OK {
                if let locator = selectorView.getResult(), let selectedArea = self.gameView?.selectionModel.selectedMapArea {
                    self.gameView?.addAsset(locator, atX: selectedArea.x, y: selectedArea.y)
                }
            }
        }
    }
    
    @objc
    func addLight() {
        gameView?.add(light: PointLight(name: "New Light", color: CGColor.white, position: SIMD3(0, 0, 5), falloff: PointLight.Falloff(near: 0, far: 5, exponent: 0.5)))
    }
    
    @objc
    func selectAmbientLight() {
        gameView?.selectionModel.setSelectable(gameView?.ambientLightEntity?.findSelectableComponent())
    }
    
    @objc
    func toggleLighting(_ sender: NSToolbarItem) {
        if let gameView {
            gameView.lightingEnabled = !gameView.lightingEnabled
            let symbolName = gameView.lightingEnabled ? "lightbulb.circle.fill" : "lightbulb.circle"
            sender.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Toggle Lighting")
        }
    }
    
    @objc
    func openAssetEditor() {
        AssetEditor.open()
    }
    
    func saveCurrentMapIfModified() -> Bool {
        guard let gameView else { return true }
        
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
        guard let gameView else { return false }
        
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
    func newMap() {
        if saveCurrentMapIfModified() {
            gameView?.unloadMap()
            currentMapURL = nil
            app?.updateWindowTitle()
        }
    }
    
    @objc
    func loadMap() {
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
                gameView?.loadMap(file: currentMapURL!)
                app?.updateWindowTitle()
            }
        }
    }
    
    @objc
    func saveMap() {
        let _ = saveCurrentMap()
    }
    
    @objc
    func saveMapAs() {
        let _ = saveCurrentMap(forceFileSelection: true)
    }
    
    @objc
    func deleteCurrentSelectable() {
        gameView?.selectionManager?.deleteCurrentSelectable()
    }
    
    @objc
    func increaseElevationForWholeMap() {
        gameView?.increaseElevation(area: nil)
    }
    
    @objc
    func decreaseElevationForWholeMap() {
        gameView?.decreaseElevation(area: nil)
    }
    
    @objc
    func deselectAll() {
        gameView?.selectionManager?.deselect()
    }
    
}
