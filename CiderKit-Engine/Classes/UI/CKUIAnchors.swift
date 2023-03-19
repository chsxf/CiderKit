import CiderCSSKit

public struct CKUIAnchors {
    
    public var xmin: Float
    public var xmax: Float
    public var ymin: Float
    public var ymax: Float
    
    public init(xmin: Float = 0, xmax: Float = 0, ymin: Float = 0, ymax: Float = 0) {
        self.xmin = xmin
        self.xmax = xmax
        self.ymin = ymin
        self.ymax = ymax
    }
    
    init(values: [CSSValue]) {
        guard
            values.count == 4,
            case let .number(xmin, _) = values[0],
            case let .number(xmax, _) = values[1],
            case let .number(ymin, _) = values[2],
            case let .number(ymax, _) = values[3]
        else {
            self.init()
            return
        }
        
        self.init(xmin: xmin, xmax: xmax, ymin: ymin, ymax: ymax)
    }
    
    func toCSSValues() -> [CSSValue] {
        [
            .number(xmin, .none),
            .number(xmax, .none),
            .number(ymin, .none),
            .number(ymax, .none)
        ]
    }
    
    func computeSize(from referenceSize: CGSize) -> CGSize {
        let widthMin = referenceSize.width * xmin
        let widthMax = referenceSize.width * xmax
        let width = widthMax - widthMin
        let heightMin = referenceSize.height * ymin
        let heightMax = referenceSize.height * ymax
        let height = heightMax - heightMin
        return CGSize(width: width, height: height)
    }
    
    func computeAnchoredFrame(from referenceFrame: CGRect) -> CGRect {
        let newOriginX = referenceFrame.minX + (referenceFrame.width * xmin)
        let newOriginY = referenceFrame.minY + (referenceFrame.height * ymin)
        let newWidth = referenceFrame.width * (xmax - xmin)
        let newHeight = referenceFrame.height * (ymax - ymin)
        return CGRect(x: newOriginX, y: newOriginY, width: newWidth, height: newHeight)
    }
    
}
