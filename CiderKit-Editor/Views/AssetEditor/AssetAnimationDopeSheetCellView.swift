import AppKit
import SpriteKit
import CiderKit_Engine
import CiderKit_Tween

class AssetAnimationDopeSheetCellView: AssetAnimationTrackBaseView {
    
    private static let frameWidth: CGFloat = 7
    
    private weak var animationControlDelegate: AssetAnimationControlDelegate? = nil
    
    private var animationTrack: AssetAnimationTrack { assetDescription.animations[animationControlDelegate!.currentAnimationName!]!.animationTracks[trackIdentifier]! }
    
    private var notificationTask: Task<Void, Never>? = nil
    
    init(tableView: NSTableView, row: Int, assetDescription: AssetDescription, trackIdentifier: AssetAnimationTrackIdentifier, animationControlDelegate: AssetAnimationControlDelegate) {
        super.init(tableView: tableView, row: row, assetDescription: assetDescription, trackIdentifier: trackIdentifier)
        
        self.animationControlDelegate = animationControlDelegate
        
        notificationTask = setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        notificationTask?.cancel()
    }
    
    private func setupNotifications() -> Task<Void, Never> {
        Task {
            guard
                let tableView = self.tableView,
                let animationControlDelegate = self.animationControlDelegate
            else { return }
            
            await withThrowingTaskGroup { group in
                group.addTask {
                    for await _ in NotificationCenter.default.notifications(named: NSTableView.selectionDidChangeNotification, object: tableView) {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.onTableViewSelectionDidChange()
                        }
                    }
                }
                
                group.addTask {
                    for await _ in NotificationCenter.default.notifications(named: .animationCurrentFrameDidChange, object: animationControlDelegate) {
                        try Task.checkCancellation()
                        await MainActor.run {
                            self.onAnimationCurrentFrameDidChange()
                        }
                    }
                }
            }
        }
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
        
        let firstFrameIndex = UInt(Float(dirtyRect.minX / Self.frameWidth).rounded(.down))
        let lastFrameIndex = UInt(Float(dirtyRect.maxX / Self.frameWidth).rounded(.up))
        
        for frameIndex in firstFrameIndex...lastFrameIndex {
            var path = allTicksPath
            if frameIndex > 0 {
                if frameIndex % 60 == 0 {
                    path = tickEverySecondPath
                }
                else if frameIndex % 10 == 0 {
                    path = tickEveryTenthPath
                }
            }
            
            let x = CGFloat(frameIndex) * Self.frameWidth
            path.move(to: NSPoint(x: x, y: 0))
            path.line(to: NSPoint(x: x, y: frame.height))
            
            if animationTrack.hasKey(at: frameIndex) {
                keysPath.appendOval(in: NSRect(x: x + 1, y: 2, width: 4, height: 4))
            }
        }
        
        var leftmostKey = animationTrack.getKey(at: firstFrameIndex) ?? animationTrack.getPrevKey(from: firstFrameIndex)
        var rightmostKey = animationTrack.getKey(at: lastFrameIndex) ?? animationTrack.getNextKey(from: lastFrameIndex)
        if leftmostKey != nil && rightmostKey == nil {
            rightmostKey = animationTrack.getPrevKey(from: lastFrameIndex)
        }
        else if leftmostKey == nil && rightmostKey != nil {
            leftmostKey = animationTrack.getNextKey(from: firstFrameIndex)
        }
        
        if let leftmostKey, let rightmostKey {
            let x = CGFloat(leftmostKey.frame) * Self.frameWidth
            let w = CGFloat(rightmostKey.frame - leftmostKey.frame + 1) * Self.frameWidth
            let backgroundRect = NSRect(x: x, y: 0, width: w, height: dirtyRect.height)
            keyBackgroundsPath.appendRect(backgroundRect)
        }
        
        var color: NSColor
        
        if let animationControlDelegate {
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
        
        if isSelected, let animationControlDelegate {
            let currentFrameRect = NSRect(x: CGFloat(animationControlDelegate.currentAnimationFrame) * Self.frameWidth, y: 0, width: Self.frameWidth, height: frame.height)
            if dirtyRect.intersects(currentFrameRect) {
                color = NSColor.controlAccentColor
                color.setStroke()
                NSBezierPath.stroke(currentFrameRect)
            }
        }
    }
    
    private func onTableViewSelectionDidChange() {
        refreshSelectedAnimation()
        if wasSelected != isSelected {
            setNeedsDisplay(visibleRect)
        }
    }
    
    private func onAnimationCurrentFrameDidChange() {
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
                for easing in Easing.allCases {
                    menuItem = NSMenuItem(title: easing.description, action: #selector(Self.setTimingInterpolation(_:)), keyEquivalent: "")
                    menuItem.state = key!.timingInterpolation.description == easing.description ? .on : .off
                    menuItem.target = self
                    menuItem.representedObject = easing
                    timingInterpolationSubmenu.addItem(menuItem)
                }

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
            let timingMode = sender.representedObject as? Easing
        else { return }
        
        let currentFrame = animationControlDelegate.currentAnimationFrame
        if let key = animationTrack.getKey(at: currentFrame) {
            key.timingInterpolation = timingMode
        }
    }
}
