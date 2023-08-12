extension XMLElement {
    
    func firstElement(forName name: String) -> XMLElement? {
        let elements = self.elements(forName: name)
        if elements.isEmpty {
            return nil
        }
        return elements[0]
    }
    
    func getDataPropertyValue(forName name: String) -> XMLNode? {
        guard let dataContainer = self.firstElement(forName: "data") else {
            return nil
        }
        
        let properties = dataContainer.elements(forName: "property")
        for property in properties {
            if property.attribute(forName: "name")?.stringValue == "text" {
                return property.attribute(forName: "value")
            }
        }
        
        return nil
    }
    
}
