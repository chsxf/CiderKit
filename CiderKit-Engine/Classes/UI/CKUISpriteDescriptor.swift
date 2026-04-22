import CiderKit_CSS

enum CKUIScalingMethod: String {
    
    case scaled
    case sliced
    
}

enum CKUISpriteDescriptor: Equatable {
    
    case sprite(String, CKUIScalingMethod, Float, Float, Float, Float)
    case spriteref(String)
    
}
