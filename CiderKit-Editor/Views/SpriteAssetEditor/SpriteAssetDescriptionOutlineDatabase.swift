import AppKit
import CiderKit_Engine

class SpriteAssetDescriptionOutlineDataSource: NSObject, NSOutlineViewDataSource {
    
    private let asset: SpriteAssetDescription
    
    init(asset: SpriteAssetDescription) {
        self.asset = asset
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return 1
        }
        else if let element = item as? SpriteAssetElement {
            return element.children.count
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return asset.rootElement
        }
        else {
            let element = item as! SpriteAssetElement
            return element.children[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        !(item as! SpriteAssetElement).children.isEmpty
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? { nil }
    
}
