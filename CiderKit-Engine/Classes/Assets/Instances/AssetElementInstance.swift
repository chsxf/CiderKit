import SpriteKit

@MainActor
public protocol AssetElementInstance: AnyObject {

    var parent: any AssetElementInstance? { get set }
    var children: [any AssetElementInstance] { get set }
    var assetInstance: AssetInstance? { get }

    var node: SKNode? { get set }

    var absoluteWorldOffset: WorldPosition { get }
    var horizontalFlipCountInAncestors: Int { get }
    var boundingBox: AssetBoundingBox? { get }

    func updateHierarchyDependentProperties()

    func getElementInstances<TResult>(options: GetElementInstancesOptions) -> [TResult] where TResult: AssetElementInstance
    func resetAllOverriddenValues(options: ResetOverriddenValuesOptions)

}
