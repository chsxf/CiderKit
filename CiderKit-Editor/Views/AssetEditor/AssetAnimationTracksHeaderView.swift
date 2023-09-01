import AppKit
import CiderKit_Engine

class AssetAnimationTracksHeaderView: NSTableHeaderView {
    
    weak var animationControlDelegate: AssetAnimationControlDelegate? = nil
    
    private(set) var currentAnimationState: String? {
        didSet {
            if currentAnimationState != oldValue {
                animationControlDelegate?.animationChangeState(self, stateName: currentAnimationState)
            }
        }
    }
    
    private let removeStateButton: NSButton
    private let stateList: NSPopUpButton
    
    private let assetDescription: AssetDescription
    
    init(frame: NSRect, asset: AssetDescription, animationState: String?) {
        assetDescription = asset
        
        let addStateButton = NSButton(systemSymbolName: "plus.rectangle.fill.on.rectangle.fill", target: nil, action: #selector(Self.addState))
        removeStateButton = NSButton(systemSymbolName: "minus.rectangle.fill", target: nil, action: #selector(Self.removeState))
        stateList = NSPopUpButton(frame: NSZeroRect, pullsDown: false)
        stateList.action = #selector(Self.selectState)
        
        super.init(frame: frame)
        
        currentAnimationState = animationState
        
        addStateButton.target = self
        removeStateButton.target = self
        stateList.target = self
        
        let stack = NSStackView(views: [stateList, addStateButton, removeStateButton])
        addSubview(stack)
        
        addConstraints([
            NSLayoutConstraint(item: stack, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: stack, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        ])
        
        updateStateList()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateStateList() {
        stateList.removeAllItems()
        if assetDescription.animationStates.isEmpty {
            stateList.addItem(withTitle: "No Animation State")
            stateList.isEnabled = false
            removeStateButton.isEnabled = false
        }
        else {
            let sortedStateNames = assetDescription.animationStates.keys.sorted()
            stateList.addItems(withTitles: sortedStateNames)
            if currentAnimationState == nil || !sortedStateNames.contains(currentAnimationState!) {
                currentAnimationState = sortedStateNames.first!
            }
            stateList.selectItem(withTitle: currentAnimationState!)
            stateList.isEnabled = true
            removeStateButton.isEnabled = true
        }
    }
    
    @objc
    private func addState() {
        let alert = NSAlert()
        alert.addButton(withTitle: "Create State")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "New Animation State"
        alert.informativeText = "Select the name of your new animation state.\n\nThis name must be unique for this asset."
        alert.alertStyle = .informational
        
        var animationStateCounter = 0
        var newAnimationStateName: String
        repeat {
            animationStateCounter += 1
            newAnimationStateName = "Animation State \(animationStateCounter)"
        }
        while assetDescription.hasAnimationState(named: newAnimationStateName)
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = newAnimationStateName
        
        alert.accessoryView = textField
        
        alert.window.initialFirstResponder = textField
        
        repeat {
            if alert.runModal() == .alertSecondButtonReturn {
                return
            }
            
            newAnimationStateName = textField.stringValue
            if assetDescription.hasAnimationState(named: newAnimationStateName) {
                let errorAlert = NSAlert()
                errorAlert.addButton(withTitle: "Ok")
                errorAlert.messageText = "Error"
                errorAlert.informativeText = "An animation state with the same name already exists fpr this asset."
                errorAlert.alertStyle = .warning
                errorAlert.runModal()
            }
            else {
                break
            }
        }
        while true
                
        assetDescription.animationStates[newAnimationStateName] = AssetAnimationState()
        currentAnimationState = newAnimationStateName
                
        updateStateList()
    }
    
    @objc
    private func removeState() {
        if let currentAnimationState = currentAnimationState {
            let alert = NSAlert()
            alert.addButton(withTitle: "Remove State")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "Confirmation"
            alert.informativeText = "Are you sure your want to remove this animation state?\n\n\(currentAnimationState)\n\nThis operation cannot be undone."
            alert.alertStyle = .critical
            
            if alert.runModal() != .alertFirstButtonReturn {
                return
            }
            
            assetDescription.animationStates[currentAnimationState] = nil
            self.currentAnimationState = nil
            updateStateList()
        }
    }
    
    @objc
    private func selectState() {
        currentAnimationState = stateList.titleOfSelectedItem
    }
    
}
