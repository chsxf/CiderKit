import Foundation
import CiderKitMacros

public enum MapRegionErrors : Error {
    case assetTooCloseToRegionBorder
    case otherAssetInTheWay
}
