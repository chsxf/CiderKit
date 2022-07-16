import AppKit

final class SpriteAssetEditor {
    
    class func open() {
        let windowRect: CGRect
        if let screen = CiderKitApp.mainWindow.screen {
            windowRect = CGRect(x: 0, y: 0, width: screen.frame.width * 0.8, height: screen.frame.height * 0.8)
        }
        else {
            windowRect = CGRect(x: 0, y: 0, width: 800, height: 600)
        }
        
        let window = NSWindow(contentRect: windowRect, styleMask: [.closable, .titled, .utilityWindow, .resizable], backing: .buffered, defer: false)
        
        CiderKitApp.mainWindow.beginSheet(window) { _ in
            
        }
    }
    
}
