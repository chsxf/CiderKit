import Cocoa
import SwiftUI
import Combine
import CiderKit_Engine
import SpriteKit

@main
final class CiderKitApp: NSObject, NSApplicationDelegate, NSWindowDelegate, NSToolbarDelegate, SKViewDelegate {

    public static let appName = "CiderKit Editor"
    public static private(set) var mainWindow: NSWindow!
    
    private(set) var window: NSWindow!
    private var gameView: EditorGameView!
    
    private var actionsManager: MainActionsManager!
    
    private var mapDirtyFlagCancellable: AnyCancellable?
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if actionsManager.saveCurrentMapIfModified() {
            return .terminateNow
        }
        return .terminateCancel
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return actionsManager.saveCurrentMapIfModified()
    }
    
    func view(_ view: SKView, shouldRenderAtTime time: TimeInterval) -> Bool {
        return window.attachedSheet == nil
    }
    
    private func setupMainWindow() -> NSWindow {
        let windowRect = CGRect(x: 100, y: 100, width: 640, height: 360)
        window = NSWindow(contentRect: windowRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.delegate = self
        window.acceptsMouseMovedEvents = true
        gameView = EditorGameView(frame: windowRect)
        gameView.delegate = self
        window.contentView = EditorMainView(gameView: gameView, frame: windowRect)
        
        actionsManager = MainActionsManager(app: self, gameView: gameView)
        
        updateWindowTitle()
        
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
        
        let mapMenu = NSMenuItem()
        mapMenu.submenu = NSMenu(title: "Map")
        mapMenu.submenu?.items = [
            NSMenuItem(title: "Increase Elevation for All Regions", target: actionsManager, action: #selector(MainActionsManager.increaseElevationForWholeMap), keyEquivalent: ""),
            NSMenuItem(title: "Decrease Elevation for All Regions", target: actionsManager, action: #selector(MainActionsManager.decreaseElevationForWholeMap), keyEquivalent: ""),
            NSMenuItem(title: "Deselect All", target: actionsManager, action: #selector(MainActionsManager.deselectAll), keyEquivalent: "")
        ]
        
        mainMenu.items = [menuItemOne, fileMenu, mapMenu]
        NSApp.mainMenu = mainMenu
    }
    
    private func setupToolbar() -> Void {
        let _ = MainToolbar(actionsManager: actionsManager, window: window)
    }
    
    private func setupNotifications() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(CiderKitApp.onElevationChangeRequested(notification:)), name: .elevationChangeRequested, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CiderKitApp.onMapDirtyStatusChanged(notification:)), name: .mapDirtyStatusChanged, object: nil)
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
        }
    }
    
    @objc
    private func onMapDirtyStatusChanged(notification: Notification) {
        updateWindowTitle()
    }
    
    func updateWindowTitle() {
        var title = "\(CiderKitApp.appName) - \(actionsManager.currentMapURL?.lastPathComponent ?? "Untitled")"
        if gameView.mutableMap.dirty {
            title += " *"
        }
        window.title = title
    }
    
    @objc
    private func onElevationChangeRequested(notification: Notification) {
        if
            let elevationToolContext = notification.object as? ElevationToolContext,
            let area = gameView.selectionModel.selectedArea
        {
            switch elevationToolContext {
            case .up:
                gameView.increaseElevation(area: area)
                
            case .down:
                gameView.decreaseElevation(area: area)
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

        Self.mainWindow = delegate.setupMainWindow()
        delegate.setupMainMenu()
        delegate.setupToolbar()
        delegate.setupNotifications()
        
        delegate.window.makeKeyAndOrderFront(nil)
        delegate.window.toggleFullScreen(nil)
        
        delegate.openProjectManagerView()
        
        NSApp.run()
    }

}
