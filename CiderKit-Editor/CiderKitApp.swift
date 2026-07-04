import Cocoa
import SwiftUI
import Combine
import CiderKit_Engine
import SpriteKit

@main
final class CiderKitApp: NSObject, NSApplicationDelegate, NSToolbarDelegate, SKViewDelegate {

    public static let appName = "CiderKit Editor"
    public static private(set) var mainWindow: NSWindow!
    
    private(set) var window: NSWindow!
    private var gameView: EditorGameView!
    
    private var actionsManager: MainActionsManager!
    
    private var mapDirtyFlagCancellable: AnyCancellable?
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task {
            if await actionsManager.saveCurrentMapIfModified() {
                sender.reply(toApplicationShouldTerminate: true)
            }
            sender.reply(toApplicationShouldTerminate: false)
        }
        return .terminateLater
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    func view(_ view: SKView, shouldRenderAtTime time: TimeInterval) -> Bool {
        window.attachedSheet == nil
    }
    
    @MainActor
    private func setupMainWindow() -> NSWindow {
        let windowRect = CGRect(x: 100, y: 100, width: 640, height: 360)
        window = NSWindow(contentRect: windowRect, styleMask: [.titled, .resizable, .miniaturizable], backing: .buffered, defer: false)
        window.acceptsMouseMovedEvents = true
        gameView = EditorGameView(frame: windowRect)
        gameView.delegate = self
        window.contentView = EditorMainView(gameView: gameView, frame: windowRect)
        
        actionsManager = MainActionsManager(app: self, gameView: gameView)
        
        return window
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
            NSMenuItem(title: "New Map", target: actionsManager, action: #selector(MainActionsManager.newMap), keyEquivalent: ""),
            NSMenuItem(title: "Load Map...", target: actionsManager, action: #selector(MainActionsManager.loadMap), keyEquivalent: ""),
            NSMenuItem(title: "Save Map", target: actionsManager, action: #selector(MainActionsManager.saveMap), keyEquivalent: ""),
            NSMenuItem(title: "Save Map As...", target: actionsManager, action: #selector(MainActionsManager.saveMapAs), keyEquivalent: "")
        ]
        
        let editMenu = NSMenuItem()
        editMenu.submenu = NSMenu(title: "Edit")
        editMenu.submenu?.items = [
            NSMenuItem(title: "Delete Currently Selected Element", target: actionsManager, action: #selector(MainActionsManager.deleteCurrentSelectable), keyEquivalent: String(Character(UnicodeScalar(NSBackspaceCharacter)!)))
        ]
        
        let mapMenu = NSMenuItem()
        mapMenu.submenu = NSMenu(title: "Map")
        mapMenu.submenu?.items = [
            NSMenuItem(title: "Increase Elevation for All Regions", target: actionsManager, action: #selector(MainActionsManager.increaseElevationForWholeMap), keyEquivalent: ""),
            NSMenuItem(title: "Decrease Elevation for All Regions", target: actionsManager, action: #selector(MainActionsManager.decreaseElevationForWholeMap), keyEquivalent: "")
        ]
        
        let selectionMenu = NSMenuItem()
        selectionMenu.submenu = NSMenu(title: "Selection")
        selectionMenu.submenu?.items = [
            NSMenuItem(title: "Deselect All", target: actionsManager, action: #selector(MainActionsManager.deselectAll), keyEquivalent: "")
        ]
        
        mainMenu.items = [menuItemOne, fileMenu, editMenu, mapMenu, selectionMenu]
        NSApp.mainMenu = mainMenu
    }
    
    private func setupToolbar() -> Void {
        let _ = MainToolbar(actionsManager: actionsManager, window: window)
    }
    
    private func setupNotifications() async -> Void {
        await withTaskGroup { group in
            group.addTask {
                for await toolContext in NotificationCenter.default.notifications(named: .elevationChangeRequested)
                                                                    .compactMap({ $0.object as? ElevationToolContext }) {
                    await self.onElevationChangeRequested(elevationToolContext: toolContext)
                }
            }
            
            group.addTask {
                for await _ in NotificationCenter.default.notifications(named: .mapDirtyStatusChanged) {
                    await self.onMapDirtyStatusChanged()
                }
            }
        }
    }
    
    private func openProjectManagerView() -> Void {
        let windowRect = CGRect(x: 0, y: 0, width: 640, height: 360)
        let pmWindow = NSWindow(contentRect: windowRect, styleMask: [.titled], backing: .buffered, defer: false)
        let pmView = ProjectManagerView(hostingWindow: pmWindow).environmentObject(ProjectManager.default)
        pmWindow.contentView = NSHostingView(rootView: pmView)
        
        window.beginSheet(pmWindow) { response in
            if response == .abort {
                NSApp.terminate(self)
            }
            else {
                Task {
                    if let gameView = self.gameView {
                        await CiderKitEngine.worldManager.unloadAllMaps()
                        let model = await CiderKitEngine.worldManager.addEmptyMap()
                        await MainActor.run {
                            let mapNode = gameView.mapNode(from: model)
                            gameView.litNodesRoot.insertChild(mapNode, at: 0)
                        }
                    }
                }
            }
        }
    }
    
    private func onMapDirtyStatusChanged() async {
        await MainActor.run { updateWindowTitle() }
    }
    
    @MainActor
    func updateWindowTitle() {
        var title = "\(CiderKitApp.appName) - \(actionsManager.currentMapURL?.lastPathComponent ?? "Untitled")"
        if gameView.mutableMap?.dirty ?? false {
            title += " *"
        }
        window.title = title
    }
    
    private func onElevationChangeRequested(elevationToolContext: ElevationToolContext) async {
        if let area = await MainActor.run(body: { gameView.selectionModel.selectedMapArea }) {
            switch elevationToolContext {
            case .up:
                await gameView.increaseElevation(area: area)

            case .down:
                await gameView.decreaseElevation(area: area)
            }
        }
    }
    
    static func main() -> Void {
        NSApp = NSApplication.shared
        
        let delegate = CiderKitApp()
        NSApp.delegate = delegate

        try! Atlases.load(atlases: [
            "default_tile": AtlasLocator(url: CiderKitEngine.bundle.url(forResource: "Default Tile Atlas", withExtension: "ckatlas")!, bundle: CiderKitEngine.bundle),
            "grid": AtlasLocator(url: Bundle.main.url(forResource: "Grid Atlas", withExtension: "ckatlas")!, bundle: Bundle.main)
        ])

        CiderKitEngine.registerBuiltinFeatures()
        AssetElementViewTypeRegistry.registerBuiltinTypes()
        
        Self.mainWindow = delegate.setupMainWindow()
        delegate.setupMainMenu()
        delegate.setupToolbar()
        
        delegate.window.makeKeyAndOrderFront(nil)
        delegate.window.toggleFullScreen(nil)

        delegate.openProjectManagerView()
        delegate.updateWindowTitle()

        Task {
            await delegate.setupNotifications()
        }

        NSApp.run()
    }

}
