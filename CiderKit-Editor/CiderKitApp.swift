//
//  AppDelegate.swift
//  SKTestIsoMap
//
//  Created by Christophe on 17/07/2021.
//

import Cocoa
import SwiftUI
import UniformTypeIdentifiers
import Combine

@main
class CiderKitApp: NSObject, NSApplicationDelegate, NSWindowDelegate {

    private static let baseWindowTitle = "CiderKit Editor"
    
    private var window: NSWindow!
    private var gameView: EditorGameView!
    private var toolsDelegate: ToolsDelegate?
    
    private var currentMapURL: URL? = nil
    
    private var cancellable: AnyCancellable?
    
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
        let sceneSize = Screen.getBestMatchingSceneSizeOnMainScreen(CGSize(width: 640, height: 360))
        
        let windowRect = NSRect(x: 100, y: 100, width: sceneSize.width, height: sceneSize.height)
        window = NSWindow(contentRect: windowRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.delegate = self
        window.acceptsMouseMovedEvents = true
        gameView = EditorGameView(frame: windowRect)
        toolsDelegate = gameView
        window.contentView = gameView
        window.makeKeyAndOrderFront(nil)
        window.toggleFullScreen(nil)
        
        let panelRect = NSRect(x: 100, y: 100, width: 200, height: 600)
        let panel = NSPanel(contentRect: panelRect, styleMask: [.utilityWindow, .titled], backing: .buffered, defer: false)
        panel.title = "Inspector"
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        let inspectorView = InspectorView().environmentObject(gameView.selectionModel)
        panel.contentView = NSHostingView(rootView: inspectorView)
        panel.orderFront(nil)
        
        let toolsPanelRect = NSRect(x: 150, y: 150, width: 200, height: 600)
        let toolsPanel = NSPanel(contentRect: toolsPanelRect, styleMask: [.utilityWindow, .titled], backing: .buffered, defer: false)
        toolsPanel.title = "Tools"
        toolsPanel.isFloatingPanel = true
        toolsPanel.becomesKeyOnlyIfNeeded = true
        var toolsView = ToolsView()
        toolsView.delegate = gameView
        toolsPanel.contentView = NSHostingView(rootView: toolsView.environmentObject(gameView.selectionModel))
        toolsPanel.orderFront(nil)
        
        updateWindowTitle()
        observeMapDirtyFlag()
    }
    
    private func setupMainMenu() -> Void {
        let applicationName = ProcessInfo.processInfo.processName
        let mainMenu = NSMenu()
        
        let menuItemOne = NSMenuItem()
        menuItemOne.submenu = NSMenu(title: "menuItemOne")
        menuItemOne.submenu?.items = [
            NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
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
    
    private func observeMapDirtyFlag() {
        cancellable = gameView.map.objectWillChange.sink { _ in
            DispatchQueue.main.async {
                self.updateWindowTitle()
            }
        }
    }
    
    private func updateWindowTitle() {
        var title = "\(CiderKitApp.baseWindowTitle) - \(currentMapURL?.lastPathComponent ?? "Untitled")"
        if gameView.map.dirty {
            title += " *"
        }
        window.title = title
    }
    
    private func saveCurrentMapIfModified() -> Bool {
        var shouldSave = false
        if gameView.map.dirty {
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
            if let type = UTType("com.xhaleera.CiderKit.map") {
                savePanel.allowedContentTypes = [ type ]
            }
            let response = savePanel.runModal()
            if response == .OK {
                selectedURL = savePanel.url
            }
        }
        
        if selectedURL != nil {
            let mapDescription = gameView.map.toMapDescription()
            if EditorFunctions.save(mapDescription, to: selectedURL!) {
                currentMapURL = selectedURL
                gameView.map.clearDirtyFlag()
                return true
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
    private func increaseElevationForWholeMap() {
        toolsDelegate?.increaseElevation(area: nil)
    }
    
    @objc
    private func decreaseElevationForWholeMap() {
        toolsDelegate?.decreaseElevation(area: nil)
    }
    
    static func main() -> Void {
        NSApp = NSApplication.shared
        
        let delegate = CiderKitApp()
        NSApp.delegate = delegate
        
        try? Atlases.preload(atlases: [
            "main": "Main Atlas",
            "grid": "Grid Atlas"
        ]) {
            DispatchQueue.main.async {
                delegate.setup()
                delegate.setupMainMenu()
            }
        }
        
        NSApp.run()
    }

}
