import Foundation
import CiderKitMacros

public enum MapRegionErrors : Error {
    case assetOutside
    case assetTooCloseToRegionBorder
    case otherAssetInTheWay
}
