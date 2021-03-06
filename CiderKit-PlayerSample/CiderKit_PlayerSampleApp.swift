import Cocoa
import SwiftUI
import CiderKit_Engine

@main
class CiderKit_PlayerSampleApp: NSObject, NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func setup() -> Void {
        let windowRect = NSRect(x: 100, y: 100, width: 640, height: 360)
        let window = NSWindow(contentRect: windowRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.acceptsMouseMovedEvents = true
        window.title = "CiderKit Player Sample"
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
            NSMenuItem(title: "Quit CiderKit Player Sample", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        ]
        
        mainMenu.items = [menuItemOne]
        NSApp.mainMenu = mainMenu
    }
    
    static func main() -> Void {
        NSApp = NSApplication.shared
        
        let delegate = CiderKit_PlayerSampleApp()
        NSApp.delegate = delegate
        
        Task.detached {
            try? await Atlases.preload(atlases: [
                "main": "Main Atlas"
            ])
            
            DispatchQueue.main.async {
                delegate.setup()
                delegate.setupMainMenu()
            }
        }
        
        NSApp.run()
    }

}
