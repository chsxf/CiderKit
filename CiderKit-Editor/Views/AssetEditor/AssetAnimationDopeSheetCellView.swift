import AppKit
import SpriteKit
import CiderKit_Engine

class AssetAnimationDopeSheetCellView: AssetAnimationTrackBaseView {
    
    private static let frameWidth: CGFloat = 7
    
    private weak var animationControlDelegate: AssetAnimationControlDelegate? = nil
    
    private var animationTrack: AssetAnimationTrack { assetDescription.animationStates[animationControlDelegate!.currentAnimationStateName!]!.animationTracks[trackIdentifier]! }
    
    init(tableView: NSTableView, row: Int, assetDescription: AssetDescription, trackIdentifier: AssetAnimationTrackIdentifier, animationControlDelegate: AssetAnimationControlDelegate) {
        super.init(tableView: tableView, row: row, assetDescription: assetDescription, trackIdentifier: trackIdentifier)
        
        self.animationControlDelegate = animationControlDelegate
        
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onTableViewSelectionDidChange(_:)), name: NSTableView.selectionDidChangeNotification, object: tableView)
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onAnimationCurrentFrameDidChange(_:)), name: .animationCurrentFrameDidChange, object: animationControlDelegate)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if isSelected {
            let backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.25)
            backgroundColor.setFill()
            NSBezierPath.fill(dirtyRect)
        }
        
        let allTicksPath = NSBezierPath()
        let tickEveryTenthPath = NSBezierPath()
        let tickEverySecondPath = NSBezierPath()
        let keysPath = NSBezierPath()
        let keyBackgroundsPath = NSBezierPath()
        var frameIndex = UInt(Float(dirtyRect.minX / Self.frameWidth).rounded(.down))
        let loopMin = CGFloat(frameIndex) * Self.frameWidth
        for x in stride(from: loopMin, to: dirtyRect.maxX, by: Self.frameWidth) {
            var path = allTicksPath
            if frameIndex > 0 {
                if frameIndex % 60 == 0 {
                    path = tickEverySecondPath
                }
                else if frameIndex % 10 == 0 {
                    path = tickEveryTenthPath
                }
            }
            path.move(to: NSPoint(x: x, y: 0))
            path.line(to: NSPoint(x: x, y: frame.height))
            
            if animationTrack.hasKey(at: frameIndex) {
                var keyBackgroundRect = NSRect(x: x, y: 0, width: Self.frameWidth, height: frame.height)
                if let prevKey = animationTrack.getPrevKey(from: frameIndex) {
                    let keyMaxX = CGFloat(prevKey.frame + 1) * Self.frameWidth
                    if keyMaxX < loopMin {
                        keyBackgroundRect.origin = CGPoint(x: keyMaxX - Self.frameWidth, y: 0)
                        keyBackgroundRect.size = CGSize(width: keyBackgroundRect.width + CGFloat(frameIndex - prevKey.frame) * Self.frameWidth, height: keyBackgroundRect.height)
                    }
                }
                if let nextKey = animationTrack.getNextKey(from: frameIndex) {
                    keyBackgroundRect.size = CGSize(width: keyBackgroundRect.width + Self.frameWidth * CGFloat(nextKey.frame - frameIndex - 1), height: keyBackgroundRect.height)
                }
                keyBackgroundsPath.appendRect(keyBackgroundRect)
                
                keysPath.appendOval(in: NSRect(x: x + 1, y: 2, width: 4, height: 4))
            }
            
            frameIndex += 1
        }
        
        var color: NSColor
        
        if let animationControlDelegate = animationControlDelegate {
            let currentFrameRect = NSRect(x: CGFloat(animationControlDelegate.currentAnimationFrame) * Self.frameWidth, y: 0, width: Self.frameWidth, height: frame.height)
            if dirtyRect.intersects(currentFrameRect) {
                color = NSColor(red: 1, green: 0.5, blue: 0.5, alpha: 0.15)
                color.setFill()
                NSBezierPath.fill(currentFrameRect)
            }
        }
        
        color = NSColor(white: 1, alpha: 0.25)
        color.setFill()
        keyBackgroundsPath.fill()
        
        color = NSColor.black
        color.setFill()
        keysPath.fill()
        
        color = NSColor(white: 0, alpha: 0.25)
        color.setStroke()
        allTicksPath.stroke()
        
        color = NSColor(white: 1, alpha: 0.15)
        color.setStroke()
        tickEveryTenthPath.stroke()
        
        color = NSColor(white: 1, alpha: 0.35)
        color.setStroke()
        tickEverySecondPath.stroke()
        
        if isSelected, let animationControlDelegate = animationControlDelegate {
            let currentFrameRect = NSRect(x: CGFloat(animationControlDelegate.currentAnimationFrame) * Self.frameWidth, y: 0, width: Self.frameWidth, height: frame.height)
            if dirtyRect.intersects(currentFrameRect) {
                color = NSColor.controlAccentColor
                color.setStroke()
                NSBezierPath.stroke(currentFrameRect)
            }
        }
    }
    
    @objc
    private func onTableViewSelectionDidChange(_ notif: Notification) {
        refreshSelectedState()
        if wasSelected != isSelected {
            setNeedsDisplay(visibleRect)
        }
    }
    
    @objc
    private func onAnimationCurrentFrameDidChange(_ notif: Notification) {
        setNeedsDisplay(visibleRect)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        guard let animationControlDelegate else { return }
        
        var point = event.locationInWindow
        point = convert(point, from: nil)
        
        if frame.contains(point) {
            let frameFromPoint = UInt(point.x / Self.frameWidth)
            animationControlDelegate.animationGoToFrame(self, frame: frameFromPoint)
            
            let key = animationTrack.getKey(at: frameFromPoint)
            let hasKeyAtFrame = (key != nil)
            
            let menu = NSMenu()
            
            let addSelector = hasKeyAtFrame ? nil : #selector(Self.addKey)
            var menuItem = NSMenuItem(title: "Add key", action: addSelector, keyEquivalent: "")
            menuItem.target = self
            menu.addItem(menuItem)
            
            let removeSelector = hasKeyAtFrame ? #selector(Self.removeKey) : nil
            menuItem = NSMenuItem(title: "Remove key", action: removeSelector, keyEquivalent: "")
            menuItem.target = self
            menu.addItem(menuItem)
            
            if hasKeyAtFrame, let _ = animationTrack.getNextKey(from: frameFromPoint) {
                menu.addItem(NSMenuItem.separator())
                
                let keyPropertiesSubmenu = NSMenu()
                
                menuItem = NSMenuItem(title: "Maintains value", action: #selector(Self.toggleMaintainsValue), keyEquivalent: "")
                menuItem.target = self
                menuItem.state = key!.maintainValue ? .on : .off
                keyPropertiesSubmenu.addItem(menuItem)
                
                let timingInterpolationSubmenu = NSMenu()
                
                menuItem = NSMenuItem(title: "Linear", action: #selector(Self.setTimingInterpolation(_:)), keyEquivalent: "")
                menuItem.state = key!.timingInterpolation == .linear ? .on : .off
                menuItem.target = self
                menuItem.representedObject = SKActionTimingMode.linear
                timingInterpolationSubmenu.addItem(menuItem)
                
                menuItem = NSMenuItem(title: "Ease In", action: #selector(Self.setTimingInterpolation(_:)), keyEquivalent: "")
                menuItem.state = key!.timingInterpolation == .easeIn ? .on : .off
                menuItem.target = self
                menuItem.representedObject = SKActionTimingMode.easeIn
                timingInterpolationSubmenu.addItem(menuItem)
                
                menuItem = NSMenuItem(title: "Ease Out", action: #selector(Self.setTimingInterpolation(_:)), keyEquivalent: "")
                menuItem.state = key!.timingInterpolation == .easeOut ? .on : .off
                menuItem.target = self
                menuItem.representedObject = SKActionTimingMode.easeOut
                timingInterpolationSubmenu.addItem(menuItem)
                
                menuItem = NSMenuItem(title: "Ease In Ease Out", action: #selector(Self.setTimingInterpolation(_:)), keyEquivalent: "")
                menuItem.state = key!.timingInterpolation == .easeInEaseOut ? .on : .off
                menuItem.target = self
                menuItem.representedObject = SKActionTimingMode.easeInEaseOut
                timingInterpolationSubmenu.addItem(menuItem)
                
                menuItem = NSMenuItem(title: "Timing interpolation", action: nil, keyEquivalent: "")
                menuItem.submenu = timingInterpolationSubmenu
                keyPropertiesSubmenu.addItem(menuItem)
                
                menuItem = NSMenuItem(title: "Key properties", action: nil, keyEquivalent: "")
                menuItem.submenu = keyPropertiesSubmenu
                menu.addItem(menuItem)
            }
            
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }
    }
    
    @objc
    private func addKey() {
        let currentFrame = animationControlDelegate!.currentAnimationFrame
        let element = assetDescription.getElement(uuid: trackIdentifier.elementUUID)
        
        if let value = animationTrack.getValue(at: currentFrame, for: element) {
            try! animationTrack.setValue(value, at: currentFrame)
            setNeedsDisplay(visibleRect)
        }
    }
    
    @objc
    private func removeKey() {
        guard let animationControlDelegate else { return }
        
        let currentFrame = animationControlDelegate.currentAnimationFrame
        animationTrack.removeKey(at: currentFrame)
        setNeedsDisplay(visibleRect)
    }
    
    @objc
    private func toggleMaintainsValue() {
        guard let animationControlDelegate else { return }
        
        let currentFrame = animationControlDelegate.currentAnimationFrame
        if let key = animationTrack.getKey(at: currentFrame) {
            key.maintainValue = !key.maintainValue
        }
    }
    
    @objc
    private func setTimingInterpolation(_ sender: NSMenuItem) {
        guard
            let animationControlDelegate,
            let timingMode = sender.representedObject as? SKActionTimingMode
        else { return }
        
        let currentFrame = animationControlDelegate.currentAnimationFrame
        if let key = animationTrack.getKey(at: currentFrame) {
            key.timingInterpolation = timingMode
        }
    }
}
