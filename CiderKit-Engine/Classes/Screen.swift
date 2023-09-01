#if os(macOS)
import Foundation
import AppKit

public final class Screen {
    
    public class func getBestMatchingSceneSizeOnMainScreen(_ volumeSize: CGSize) -> CGSize {
        let baseAspectRatio = volumeSize.width / volumeSize.height
        
        let menuBarScreen = NSScreen.screens[0]
        let menuBarScreenSize = menuBarScreen.frame.size
        let screenAspectRatio = menuBarScreenSize.width / menuBarScreenSize.height
        
        var resultSize = volumeSize
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
