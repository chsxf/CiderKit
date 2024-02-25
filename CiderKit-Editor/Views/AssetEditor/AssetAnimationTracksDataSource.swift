import AppKit
import CiderKit_Engine

class AssetAnimationTracksDataSource: NSObject, NSTableViewDataSource {
    
    private let assetDescription: AssetDescription
    private let animationName: String?
    
    init(assetDescription: AssetDescription, animationName: String?) {
        self.assetDescription = assetDescription
        self.animationName = animationName
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard
            let animationName,
            let animationTracks = assetDescription.animations[animationName]?.animationTracks
        else {
            return 0
        }
        return animationTracks.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard
            let animationName,
            let animationTracks = assetDescription.animations[animationName]?.animationTracks
        else {
            return nil
        }

        let sortedAnimationTrackKeys = animationTracks.keys.sorted { lhs, rhs in
            if lhs.elementUUID == rhs.elementUUID {
                guard let element = assetDescription.getElement(uuid: lhs.elementUUID) else {
                    return false
                }
                
                let cases = element.eligibleTrackTypes
                let lIndex = cases.firstIndex(of: lhs.trackType)!
                let rIndex = cases.firstIndex(of: rhs.trackType)!
                return lIndex < rIndex
            }
            else {
                let lOrder = assetDescription.getElementOrder(uuid: lhs.elementUUID)!
                let rOrder = assetDescription.getElementOrder(uuid: rhs.elementUUID)!
                return lOrder < rOrder
            }
        }
        return sortedAnimationTrackKeys[row]
    }
    
}
