import AppKit
import CiderKit_Engine

public class ReferenceAssetElementView : TransformAssetElementView {
    
    private let referenceField: NSTextField
    private let selectReferenceButton: NSButton
    private let removeReferenceButton: NSButton
    private let animationNameCombo: NSPopUpButton
    
    required init(assetDescription: AssetDescription, element: TransformAssetElement) {
        referenceField = NSTextField(string: "None")
        referenceField.isEditable = false
        referenceField.isBezeled = true
        selectReferenceButton = NSButton(title: "Select asset...", target: nil, action: #selector(Self.selectAsset))
        removeReferenceButton = NSButton(title: "Remove", target: nil, action: #selector(Self.removeAsset))
        animationNameCombo = NSPopUpButton(title: "", target: nil, action: #selector(Self.animationNameChanged(_:)))
        
        super.init(assetDescription: assetDescription, element: element)
        
        selectReferenceButton.target = self
        removeReferenceButton.target = self
        animationNameCombo.target = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getAdditionalElementViews() -> [NSView] {
        var additionalViews = super.getAdditionalElementViews()
        
        let buttonRow = NSStackView(views: [selectReferenceButton, removeReferenceButton])
        buttonRow.orientation = .horizontal
        
        additionalViews.append(contentsOf: [
            VSpacer(), InspectorHeader(title: "Reference"), referenceField, buttonRow,
            VSpacer(), InspectorHeader(title: "Animation"), animationNameCombo
        ])
        
        return additionalViews
    }
    
    override func updateForCurrentElement(snapshot: AssetElementAnimationSnapshot? = nil) {
        guard let referenceElement = element as? ReferenceAssetElement, let assetDescription, let animationControlDelegate else {
            super.updateForCurrentElement(snapshot: nil)
            return
        }
        
        let animationSnapshot = snapshot ?? assetDescription.getAnimationSnapshot(for: referenceElement.uuid, in: animationControlDelegate.currentAnimationName, at: animationControlDelegate.currentAnimationFrame)
        super.updateForCurrentElement(snapshot: animationSnapshot)
        
        if !referenceElement.isRoot {
            animationNameCombo.removeAllItems()

            if let assetLocator = referenceElement.assetLocator {
                referenceField.stringValue = assetLocator.humanReadableDescription
                removeReferenceButton.isEnabled = true;
                
                if let assetDescription = assetLocator.assetDescription {
                    let sortedAnimationNames = [String](assetDescription.animations.keys).sorted()
                    
                    animationNameCombo.addItems(withTitles: sortedAnimationNames)
                    if animationNameCombo.numberOfItems > 0 {
                        if let referencedAnimationName = referenceElement.animationName {
                            animationNameCombo.selectItem(withTitle: referencedAnimationName)
                        }
                        animationNameCombo.isEnabled = true
                    }
                    else {
                        animationNameCombo.isEnabled = false
                    }
                }
                else {
                    animationNameCombo.isEnabled = false
                }
            }
            else {
                referenceField.stringValue = "None"
                removeReferenceButton.isEnabled = false
                animationNameCombo.isEnabled = false
            }
        }
    }
    
    @objc
    private func selectAsset() {
        let windowRect: CGRect = CGRect(x: 0, y: 0, width: 400, height: 600)

        let window = NSWindow(contentRect: windowRect, styleMask: [.resizable, .titled], backing: .buffered, defer: false)
        let selectorView = AssetSelectorView()
        window.contentView = selectorView

        self.window?.beginSheet(window) { responseCode in
            if responseCode == .OK {
                guard let locator = selectorView.getResult() else { return }
                
                if !self.assetDescription!.canAddAsset(locator) {
                    let alert = NSAlert()
                    alert.addButton(withTitle: "Ok")
                    alert.messageText = "Unable to add asset"
                    alert.informativeText = "The selected asset cannot be added because it would create cycling references."
                    alert.alertStyle = .critical
                    alert.runModal()
                    return
                }
                
                if let elementViewDelegate = self.elementViewDelegate, let referenceElement = self.element as? ReferenceAssetElement {
                    self.referenceField.stringValue = locator.humanReadableDescription
                    self.removeReferenceButton.isEnabled = true
                    referenceElement.assetLocator = locator
                    elementViewDelegate.update(element: referenceElement)
                }
            }
        }
    }
    
    @objc
    private func removeAsset() {
        if let elementViewDelegate, let referenceElement = element as? ReferenceAssetElement {
            referenceField.stringValue = "None"
            removeReferenceButton.isEnabled = false
            
            referenceElement.assetLocator = nil
            referenceElement.animationName = nil
            elementViewDelegate.update(element: referenceElement)
        }
    }
    
    @objc
    private func animationNameChanged(_ sender: NSPopUpButton) {
        guard
            let referenceElement = element as? ReferenceAssetElement,
            let selectedAnimationName = sender.titleOfSelectedItem
        else { return }
        
        referenceElement.animationName = selectedAnimationName
        updateElement()
    }
    
}
