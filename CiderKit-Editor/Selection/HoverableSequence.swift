import GameplayKit

struct HoverableSequence: Sequence, IteratorProtocol {
    
    private let arrays: [[GKEntity]]
    private var currentArrayIndex: Int = 0
    private var currentIndex: Int = -1
    
    init(_ arrays: [GKEntity]...) {
        self.arrays = arrays
    }
    
    mutating func next() -> Hoverable? {
        while arrays.count > currentArrayIndex {
            let currentArray = arrays[currentArrayIndex]
            currentIndex += 1
            
            if currentArray.count <= currentIndex {
                currentArrayIndex += 1
                currentIndex = -1
                continue
            }
            
            let entity = currentArray[currentIndex]
            if let hoverable = entity.findHoverableComponent() {
                return hoverable
            }
        }
        return nil
    }
    
}
