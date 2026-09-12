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
                MapModel.shared.hasCell(forMapX: selectedArea.x, y: selectedArea.y)
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
                    Task {
                        await self.gameView?.addAsset(locator, atMapPosition: MapPosition(x: selectedArea.x, y: selectedArea.y), horizontallyFlipped: false)
                    }
                }
            }
        }
    }
    
    @objc
    func addPointLight() {
        let description = PointLightDescription(color: CGColor.white, enabled: true, name: "New Point Light", position: WorldPosition(0, 0, 5), falloff: .init(near: 0, far: 5, exponent: 0.5))
        gameView?.add(light: PointLight(from: description))
    }

    @objc
    func addDirectionalLight() {
        let description = DirectionalLightDescription(color: CGColor.white, enabled: true, name: "New Directional Light", position: SIMD3(), orientation: SIMD2())
        gameView?.add(light: DirectionalLight(from: description))
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
    
    func saveCurrentMapIfModified() async -> Bool {
        guard let gameView else { return true }
        
        var shouldSave = false
        if await gameView.mutableMap?.dirty ?? false {
            let modalResult = await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "Would you like to save the current map?"
                alert.informativeText = "Confirmation"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Yes")
                alert.addButton(withTitle: "No")
                alert.addButton(withTitle: "Cancel")
                return alert.runModal()
            }

            switch modalResult {
            case .alertFirstButtonReturn:
                shouldSave = true
            case .alertSecondButtonReturn:
                shouldSave = false
            default:
                return false
            }
        }

        if shouldSave {
            return await saveCurrentMap()
        }
        return true
    }

    @discardableResult
    private func saveCurrentMap(forceFileSelection: Bool = false) async -> Bool {
        guard let gameView else { return false }
        
        var selectedURL: URL? = currentMapURL
        if forceFileSelection {
            selectedURL = nil
        }
        if selectedURL == nil {
            let responseURL = await MainActor.run {
                let savePanel = NSSavePanel()
                savePanel.directoryURL = Project.current?.mapsDirectoryURL
                if let type = UTType("com.xhaleera.CiderKit.map") {
                    savePanel.allowedContentTypes = [ type ]
                }
                return savePanel.runModal() == .OK ? savePanel.url : nil
            }
            if let validResponseURL = responseURL {
                selectedURL = validResponseURL
            }
        }
        
        if let validURL = selectedURL {
            do {
                let mapDescription = await MapModel.shared.currentMapDescription
                try EditorFunctions.save(mapDescription, to: validURL, prettyPrint: true)
                currentMapURL = validURL
                await MainActor.run {
                    gameView.mutableMap?.dirty = false
                }
                return true
            }
            catch {
                await MainActor.run {
                    UIHelpers.fatalErrorAlert(titled: "Error", message: "Unable to save map to file \(validURL)")
                }
            }
        }
        return false
    }
    
    @objc
    func newMap() {
        Task {
            if await saveCurrentMapIfModified() {
                await MapModel.shared.clear()
                currentMapURL = nil

                await MainActor.run {
                    app?.updateWindowTitle()

                    if let gameView {
                        let mapNode = gameView.mapNode(from: MapModel.shared)
                        gameView.litNodesRoot.insertChild(mapNode, at: 0)
                    }
                }
            }
        }
    }
    
    @objc
    func loadMap() {
        Task {
            if let gameView, await saveCurrentMapIfModified() {
                let mapURLToLoad = await MainActor.run {
                    let openPanel = NSOpenPanel()
                    openPanel.canChooseFiles = true
                    openPanel.canChooseDirectories = false
                    openPanel.directoryURL = Project.current?.mapsDirectoryURL
                    if let type = UTType("com.xhaleera.CiderKit.map") {
                        openPanel.allowedContentTypes = [ type ]
                    }
                    let response = openPanel.runModal()
                    return  response == .OK ? openPanel.urls[0] : nil
                }
                if let confirmedMapURLToLoad = mapURLToLoad {
                    Task {
                        await MapModel.shared.clear()
                        currentMapURL = nil

                        do {
                            let mapDescription: MapDescription = try Functions.load(confirmedMapURLToLoad)
                            await MapModel.shared.match(mapDescription: mapDescription)
                            currentMapURL = confirmedMapURLToLoad

                            await MainActor.run {
                                let map = gameView.mapNode(from: MapModel.shared)
                                gameView.litNodesRoot.insertChild(map, at: 0)
                                app?.updateWindowTitle()
                            }
                        }
                        catch {
                            await MainActor.run {
                                UIHelpers.fatalErrorAlert(titled: "Error", message: "Unable to load map file at \(confirmedMapURLToLoad)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc
    func saveMap() {
        Task {
            await saveCurrentMap()
        }
    }
    
    @objc
    func saveMapAs() {
        Task {
            await saveCurrentMap(forceFileSelection: true)
        }
    }
    
    @objc
    func deleteCurrentSelectable() {
        gameView?.selectionManager?.deleteCurrentSelectable()
    }
    
    @objc
    func increaseElevationForWholeMap() {
        Task {
            await gameView?.increaseElevation(area: nil)
        }
    }
    
    @objc
    func decreaseElevationForWholeMap() {
        Task {
            await gameView?.decreaseElevation(area: nil)
        }
    }
    
    @objc
    func deselectAll() {
        gameView?.selectionManager?.deselect()
    }
    
}
