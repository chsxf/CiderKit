import AppKit
import CiderKit_Engine

class AssetDescriptionOutlineDataSource: NSObject, NSOutlineViewDataSource {
    
    private let asset: AssetDescription
    
    init(asset: AssetDescription) {
        self.asset = asset
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return 1
        }
        else if let element = item as? TransformAssetElement {
            return element.children.count
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return asset.rootElement
        }
        else {
            let element = item as! TransformAssetElement
            return element.children[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        !(item as! TransformAssetElement).children.isEmpty
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? { nil }
    
}
