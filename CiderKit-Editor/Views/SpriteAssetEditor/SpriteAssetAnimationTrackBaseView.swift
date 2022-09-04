import AppKit
import CiderKit_Engine

class SpriteAssetAnimationTrackBaseView: NSView {
    
    weak var tableView: NSTableView? = nil
    let row: Int
    let assetDescription: SpriteAssetDescription
    let trackIdentifier: SpriteAssetAnimationTrackIdentifier
    
    private(set) var wasSelected: Bool = false
    private(set) var isSelected: Bool = false
    
    init(tableView: NSTableView, row: Int, assetDescription: SpriteAssetDescription, trackIdentifier: SpriteAssetAnimationTrackIdentifier) {
        self.tableView = tableView
        self.row = row
        self.assetDescription = assetDescription
        self.trackIdentifier = trackIdentifier
        
        super.init(frame: NSZeroRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refreshSelectedState() {
        wasSelected = isSelected
        isSelected = tableView?.isRowSelected(row) ?? false
    }
    
}
