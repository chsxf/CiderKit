#if os(macOS)
import Foundation
import AppKit

public final class Screen {
    
    public class func getBestMatchingSceneSizeOnMainScreen(_ volumeWorldSize: CGSize) -> CGSize {
        let baseAspectRatio = volumeWorldSize.width / volumeWorldSize.height
        
        let menuBarScreen = NSScreen.screens[0]
        let menuBarScreenSize = menuBarScreen.frame.size
        let screenAspectRatio = menuBarScreenSize.width / menuBarScreenSize.height
        
        var resultSize = volumeWorldSize
        if screenAspectRatio > baseAspectRatio {
            resultSize.width = (resultSize.height * screenAspectRatio).rounded(.awayFromZero)
        }
        else {
            resultSize.height = (resultSize.width / screenAspectRatio).rounded(.awayFromZero)
        }
        return resultSize
    }
    
}
#endif
