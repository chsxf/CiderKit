extension XMLElement {
    
    func firstElement(forName name: String) -> XMLElement? {
        let elements = self.elements(forName: name)
        if elements.isEmpty {
            return nil
        }
        return elements[0]
    }
    
}
