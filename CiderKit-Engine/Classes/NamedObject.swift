public protocol NamedObject {

    var name: String { get }

    func rename(_ newName: String) async

}
