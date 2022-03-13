//
//  AppDelegate.swift
//  SKTestIsoMap
//
//  Created by Christophe on 17/07/2021.
//

import Cocoa
import SwiftUI

@main
class CiderKitApp: NSObject, NSApplicationDelegate {

    private var toolsDelegate: ToolsDelegate?
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func setup() -> Void {
        let sceneSize = Screen.getBestMatchingSceneSizeOnMainScreen(CGSize(width: 640, height: 360))
        
        let windowRect = NSRect(x: 100, y: 100, width: sceneSize.width, height: sceneSize.height)
        let window = NSWindow(contentRect: windowRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.acceptsMouseMovedEvents = true
        window.title = "Cider Kit Editor"
        let gameView = EditorGameView(frame: windowRect)
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
    }
    
    private func setupMainMenu() -> Void {
        let applicationName = ProcessInfo.processInfo.processName
        let mainMenu = NSMenu()
        
        let menuItemOne = NSMenuItem()
        menuItemOne.submenu = NSMenu(title: "menuItemOne")
        menuItemOne.submenu?.items = [
            NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        ]
        
        let mapMenu = NSMenuItem()
        mapMenu.submenu = NSMenu(title: "Map")
        mapMenu.submenu?.items = [
            NSMenuItem(title: "Increase Elevation for Whole Map", action: #selector(self.increaseElevationForWholeMapFromMainMenu), keyEquivalent: ""),
            NSMenuItem(title: "Decrease Elevation for Whole Map", action: #selector(self.decreaseElevationForWholeMapFromMainMenu), keyEquivalent: "")
        ]
        
        mainMenu.items = [menuItemOne, mapMenu]
        NSApp.mainMenu = mainMenu
    }
    
    @objc
    private func increaseElevationForWholeMapFromMainMenu() {
        toolsDelegate?.increaseElevation(area: nil)
    }
    
    @objc
    private func decreaseElevationForWholeMapFromMainMenu() {
        toolsDelegate?.decreaseElevation(area: nil)
    }
    
    static func main() -> Void {
        NSApp = NSApplication.shared
        
        let delegate = CiderKitApp()
        NSApp.delegate = delegate
        
        delegate.setup()
        delegate.setupMainMenu()
        
        NSApp.run()
    }

}
