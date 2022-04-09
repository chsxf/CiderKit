import Foundation
import AppKit

public class Screen {
    
    public class func getBestMatchingSceneSizeOnMainScreen(_ size: CGSize) -> CGSize {
        guard let mainScreen = NSScreen.main else {
            return size
        }
        
        let baseAspectRatio = size.width / size.height
        
        let mainScreenSize = mainScreen.frame.size
        let screenAspectRatio = mainScreenSize.width / mainScreenSize.height
        
        var resultSize = size
        if screenAspectRatio > baseAspectRatio {
            resultSize.width = (resultSize.height * screenAspectRatio).rounded(.awayFromZero)
        }
        else {
            resultSize.height = (resultSize.width / screenAspectRatio).rounded(.awayFromZero)
        }
        return resultSize
    }
    
}
