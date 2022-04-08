//
//  AppDelegate.swift
//  SKTestIsoMap
//
//  Created by Christophe on 17/07/2021.
//

import Cocoa
import SwiftUI
import CiderKit_Engine

@main
class CiderKitApp: NSObject, NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func setup() -> Void {
        let sceneSize = Screen.getBestMatchingSceneSizeOnMainScreen(CGSize(width: 640, height: 360))
        
        let windowRect = NSRect(x: 100, y: 100, width: sceneSize.width, height: sceneSize.height)
        let window = NSWindow(contentRect: windowRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.acceptsMouseMovedEvents = true
        window.title = "CiderKit Player"
        let gameView = GameView(frame: windowRect)
        window.contentView = gameView
        window.makeKeyAndOrderFront(nil)
        window.toggleFullScreen(nil)
        
        let url = Bundle.main.url(forResource: "map", withExtension: "ckmap")
        gameView.loadMap(file: url!)
    }
    
    private func setupMainMenu() -> Void {
        let mainMenu = NSMenu()
        
        let menuItemOne = NSMenuItem()
        menuItemOne.submenu = NSMenu(title: "menuItemOne")
        menuItemOne.submenu?.items = [
            NSMenuItem(title: "Quit CiderKit Player", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        ]
        
        mainMenu.items = [menuItemOne]
        NSApp.mainMenu = mainMenu
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
