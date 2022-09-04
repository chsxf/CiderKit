import AppKit
import CoreGraphics

class SpriteAssetAnimationDopeSheetHeaderView: NSTableHeaderView {
    
    private static let frameWidth: CGFloat = 7
    
    private weak var animationControlDelegate: SpriteAssetAnimationControlDelegate? = nil
    
    init(frame: NSRect, animationControlDelegate: SpriteAssetAnimationControlDelegate) {
        super.init(frame: frame)
        
        self.animationControlDelegate = animationControlDelegate
        
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onAnimationCurrentFrameDidChange(_:)), name: .animationCurrentFrameDidChange, object: animationControlDelegate)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        var color = NSColor.windowBackgroundColor
        color.setFill()
        NSBezierPath.fill(dirtyRect)
        
        let textAttributes = [
            NSAttributedString.Key.foregroundColor: NSColor(white: 1, alpha: 0.5),
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: NSFont.systemFontSize * 0.8)
        ]
        
        let allTicksPath = NSBezierPath()
        let tickEveryTenthPath = NSBezierPath()
        let tickEverySecondPath = NSBezierPath()
        
        var counter = 1
        for x in stride(from: Self.frameWidth, to: dirtyRect.maxX, by: Self.frameWidth) {
            if x >= dirtyRect.minX {
                var path = allTicksPath
                var offset = 8
                if counter % 60 == 0 {
                    path = tickEverySecondPath
                    offset = 12
                    let str = "\(counter / 60)\""
                    str.draw(at: NSPoint(x: x - 3, y: 2), withAttributes: textAttributes)
                }
                else if counter % 10 == 0 {
                    path = tickEveryTenthPath
                    let str = "\(counter % 60)"
                    str.draw(at: NSPoint(x: x - 6, y: 6), withAttributes: textAttributes)
                }
                path.move(to: NSPoint(x: x, y: frame.height))
                path.line(to: NSPoint(x: x, y: frame.height - CGFloat(offset)))
            }
            counter += 1
        }
        
        if let animationControlDelegate = animationControlDelegate {
            let currentFrameRect = NSRect(x: CGFloat(animationControlDelegate.currentAnimationFrame) * Self.frameWidth, y: 0, width: Self.frameWidth, height: frame.height)
            if dirtyRect.intersects(currentFrameRect) {
                color = NSColor(red: 1, green: 0.5, blue: 0.5, alpha: 0.35)
                color.setFill()
                NSBezierPath.fill(currentFrameRect)
            }
        }
        
        color = NSColor(white: 0, alpha: 0.25)
        color.setStroke()
        allTicksPath.stroke()
        
        color = NSColor(white: 1, alpha: 0.15)
        color.setStroke()
        tickEveryTenthPath.stroke()
        
        color = NSColor(white: 1, alpha: 0.35)
        color.setStroke()
        tickEverySecondPath.move(to: NSPoint(x: 0, y: frame.height))
        tickEverySecondPath.line(to: NSPoint(x: frame.width, y: frame.height))
        tickEverySecondPath.stroke()
    }
    
    override func mouseDown(with event: NSEvent) {
        updateCurrentFrame(from: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        updateCurrentFrame(from: event)
    }
    
    private func updateCurrentFrame(from event: NSEvent) {
        guard let animationControlDelegate else { return }
        
        if animationControlDelegate.isPlaying {
            animationControlDelegate.animationTogglePlay(self)
        }
        
        var point = event.locationInWindow
        point = convert(point, from: nil)
        
        if frame.contains(point) {
            let frameFromPoint = Int(point.x / Self.frameWidth)
            animationControlDelegate.animationGoToFrame(self, frame: frameFromPoint)
        }
    }
    
    @objc
    private func onAnimationCurrentFrameDidChange(_ notif: Notification) {
        setNeedsDisplay(visibleRect)
    }
    
}
