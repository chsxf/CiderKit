extension XMLNode {
    
    var floatValue: Float? { Float(self.stringValue ?? "0") }
    
}
