import AppKit
import CiderKit_Engine

class AssetAnimationTracksDataSource: NSObject, NSTableViewDataSource {
    
    private let asset: AssetDescription
    private let animationState: String?
    
    init(asset: AssetDescription, animationState: String?) {
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
                guard let element = asset.getElement(uuid: lhs.elementUUID) else {
                    return false
                }
                
                let cases = element.eligibleTrackTypes
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
