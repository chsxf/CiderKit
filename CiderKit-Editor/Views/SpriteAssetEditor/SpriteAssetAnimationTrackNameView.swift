import AppKit
import CiderKit_Engine

protocol SpriteAssetAnimationTrackNameViewDelegate: AnyObject {
 
    func trackNameView(_ view: SpriteAssetAnimationTrackNameView, requestingTrackRemoval track: SpriteAssetAnimationTrackIdentifier)
    
}

class SpriteAssetAnimationTrackNameView: SpriteAssetAnimationTrackBaseView {
    
    weak var delegate: SpriteAssetAnimationTrackNameViewDelegate? = nil
    
    override init(tableView: NSTableView, row: Int, assetDescription: SpriteAssetDescription, trackIdentifier: SpriteAssetAnimationTrackIdentifier) {
        super.init(tableView: tableView, row: row, assetDescription: assetDescription, trackIdentifier: trackIdentifier)
        
        let image = NSImage(systemSymbolName: trackIdentifier.trackType.systemSymbolName, accessibilityDescription: nil)
        let imageView = NSImageView(frame: NSRect(x: 2, y: 2, width: 20, height: 20))
        imageView.image = image
        addSubview(imageView)
        
        let elementName = assetDescription.getElement(uuid: trackIdentifier.elementUUID)!.name
        let attributedString = try! NSAttributedString(markdown: "**\(elementName)** \(trackIdentifier.trackType.description)")
        let text = NSTextField(labelWithAttributedString: attributedString)
        text.translatesAutoresizingMaskIntoConstraints = false
        addSubview(text)
        
        let removeTrackButton = NSButton(systemSymbolName: "minus", target: self, action: #selector(Self.removeTrackButtonClicked))
        removeTrackButton.translatesAutoresizingMaskIntoConstraints = false
        removeTrackButton.setFrameSize(NSSize(width: 20, height: 20))
        addSubview(removeTrackButton)
        
        addConstraints([
            NSLayoutConstraint(item: text, attribute: .left, relatedBy: .equal, toItem: imageView, attribute: .right, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: text, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: removeTrackButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: removeTrackButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func removeTrackButtonClicked() {
        delegate?.trackNameView(self, requestingTrackRemoval: trackIdentifier)
    }
    
}
