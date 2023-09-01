import AppKit

extension NSStackView {
    
    convenience init(orientation: NSUserInterfaceLayoutOrientation, distribution: NSStackView.Distribution = .fillEqually, views: [NSView]) {
        self.init(views: views)
        self.orientation = orientation
        self.distribution = distribution
    }
    
}
