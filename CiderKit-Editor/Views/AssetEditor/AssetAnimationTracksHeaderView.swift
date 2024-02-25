import AppKit
import CiderKit_Engine

class AssetAnimationTracksHeaderView: NSTableHeaderView {
    
    weak var animationControlDelegate: AssetAnimationControlDelegate? = nil
    
    private(set) var currentAnimationName: String? {
        didSet {
            if currentAnimationName != oldValue {
                animationControlDelegate?.animationChangeAnimation(self, animationName: currentAnimationName)
            }
        }
    }
    
    private let removeAnimationButton: NSButton
    private let animationList: NSPopUpButton
    
    public var assetDescription: AssetDescription {
        didSet {
            updateAnimationList()
        }
    }
    
    init(frame: NSRect, assetDescription: AssetDescription, animationName: String?) {
        self.assetDescription = assetDescription
        
        let addAnimationButton = NSButton(systemSymbolName: "plus.rectangle.fill.on.rectangle.fill", target: nil, action: #selector(Self.addAnimation))
        removeAnimationButton = NSButton(systemSymbolName: "minus.rectangle.fill", target: nil, action: #selector(Self.removeAnimation))
        animationList = NSPopUpButton(frame: NSZeroRect, pullsDown: false)
        animationList.action = #selector(Self.selectAnimation)
        
        super.init(frame: frame)
        
        currentAnimationName = animationName
        
        addAnimationButton.target = self
        removeAnimationButton.target = self
        animationList.target = self
        
        let stack = NSStackView(views: [animationList, addAnimationButton, removeAnimationButton])
        addSubview(stack)
        
        addConstraints([
            NSLayoutConstraint(item: stack, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: stack, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        ])
        
        updateAnimationList()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateAnimationList() {
        animationList.removeAllItems()
        if assetDescription.animations.isEmpty {
            animationList.addItem(withTitle: "No Animation")
            animationList.isEnabled = false
            removeAnimationButton.isEnabled = false
        }
        else {
            let sortedAnimationNames = assetDescription.animations.keys.sorted()
            animationList.addItems(withTitles: sortedAnimationNames)
            if currentAnimationName == nil || !sortedAnimationNames.contains(currentAnimationName!) {
                currentAnimationName = sortedAnimationNames.first!
            }
            animationList.selectItem(withTitle: currentAnimationName!)
            animationList.isEnabled = true
            removeAnimationButton.isEnabled = true
        }
    }
    
    @objc
    private func addAnimation() {
        let alert = NSAlert()
        alert.addButton(withTitle: "Create Animation")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "New Animation"
        alert.informativeText = "Select the name of your new animation.\n\nThis name must be unique for this asset."
        alert.alertStyle = .informational
        
        var animationNameCounter = 0
        var newAnimationName: String
        repeat {
            animationNameCounter += 1
            newAnimationName = "Animation \(animationNameCounter)"
        }
        while assetDescription.hasAnimation(named: newAnimationName)
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = newAnimationName
        
        alert.accessoryView = textField
        
        alert.window.initialFirstResponder = textField
        
        repeat {
            if alert.runModal() == .alertSecondButtonReturn {
                return
            }
            
            newAnimationName = textField.stringValue
            if assetDescription.hasAnimation(named: newAnimationName) {
                let errorAlert = NSAlert()
                errorAlert.addButton(withTitle: "Ok")
                errorAlert.messageText = "Error"
                errorAlert.informativeText = "An animation with the same name already exists fpr this asset."
                errorAlert.alertStyle = .warning
                errorAlert.runModal()
            }
            else {
                break
            }
        }
        while true
                
        assetDescription.animations[newAnimationName] = AssetAnimation()
        currentAnimationName = newAnimationName
                
        updateAnimationList()
    }
    
    @objc
    private func removeAnimation() {
        if let currentAnimationName {
            let alert = NSAlert()
            alert.addButton(withTitle: "Remove Animation")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "Confirmation"
            alert.informativeText = "Are you sure your want to remove this animation?\n\n\(currentAnimationName)\n\nThis operation cannot be undone."
            alert.alertStyle = .critical
            
            if alert.runModal() != .alertFirstButtonReturn {
                return
            }
            
            assetDescription.animations[currentAnimationName] = nil
            self.currentAnimationName = nil
            updateAnimationList()
        }
    }
    
    @objc
    private func selectAnimation() {
        currentAnimationName = animationList.titleOfSelectedItem
    }
    
}
