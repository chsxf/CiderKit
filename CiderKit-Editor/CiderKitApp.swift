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

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    static private func setup() -> Void {
        let sceneSize = Screen.getBestMatchingSceneSizeOnMainScreen(CGSize(width: 640, height: 360))
        
        let windowRect = NSRect(x: 100, y: 100, width: sceneSize.width, height: sceneSize.height)
        let window = NSWindow(contentRect: windowRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.acceptsMouseMovedEvents = true
        window.title = "Cider Kit Editor"
        let gameView = EditorGameView(frame: windowRect)
        window.contentView = gameView
        window.makeKeyAndOrderFront(nil)
        window.toggleFullScreen(nil)
        
        let panelRect = NSRect(x: 100, y: 100, width: 200, height: 600)
        let panel = NSPanel(contentRect: panelRect, styleMask: [.utilityWindow, .titled], backing: .buffered, defer: false)
        panel.title = "Test"
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        
        let inspectorView = InspectorView().environmentObject(gameView.selectionModel)
        panel.contentView = NSHostingView(rootView: inspectorView)
        panel.orderFront(nil)
    }
    
    static private func setupMainMenu() -> Void {
        let applicationName = ProcessInfo.processInfo.processName
        let mainMenu = NSMenu()
        
        let menuItemOne = NSMenuItem()
        menuItemOne.submenu = NSMenu(title: "menuItemOne")
        menuItemOne.submenu?.items = [
            NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        ]
        
        mainMenu.items = [menuItemOne]
        NSApp.mainMenu = mainMenu
    }
    
    static func main() -> Void {
        NSApp = NSApplication.shared
        
        let delegate = CiderKitApp()
        NSApp.delegate = delegate
        
        setup()
        setupMainMenu()
        
        NSApp.run()
    }

}
