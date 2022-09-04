import AppKit
import CiderKit_Engine

class SpriteAssetAnimationTracksDataSource: NSObject, NSTableViewDataSource {
    
    private let asset: SpriteAssetDescription
    private let animationState: String?
    
    init(asset: SpriteAssetDescription, animationState: String?) {
        self.asset = asset
        self.animationState = animationState
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard
            let animationState = animationState,
            let animationTracks = asset.animationStates[animationState]?.animationTracks
        else {
            return 0
        }
        return animationTracks.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard
            let animationState = animationState,
            let animationTracks = asset.animationStates[animationState]?.animationTracks
        else {
            return nil
        }

        let sortedAnimationTrackKeys = animationTracks.keys.sorted { lhs, rhs in
            if lhs.elementUUID == rhs.elementUUID {
                let cases = SpriteAssetAnimationTrackType.allCases
                let lIndex = cases.firstIndex(of: lhs.trackType)!
                let rIndex = cases.firstIndex(of: rhs.trackType)!
                return lIndex < rIndex
            }
            else {
                let lOrder = asset.getElementOrder(uuid: lhs.elementUUID)!
                let rOrder = asset.getElementOrder(uuid: rhs.elementUUID)!
                return lOrder < rOrder
            }
        }
        return sortedAnimationTrackKeys[row]
    }
    
}
