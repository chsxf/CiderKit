import Foundation

public extension CKUIBaseNode {
    
    func find<T: CKUIBaseNode>(by id: String, ofType type: T.Type = CKUIBaseNode.self) -> T? {
        if self.identifier == id {
            return self as? T
        }
        
        for child in self.children {
            if let uiChild = child as? CKUIBaseNode, let foundNode = uiChild.find(by: id, ofType: type) {
                return foundNode
            }
        }
        
        return nil
    }
    
}
