import CiderKit_Engine

protocol AssetDescriptionViewDelegate: AnyObject {
    
    func descriptionView(_ view: AssetDescriptionView, nameChanged newName: String)
    
}
