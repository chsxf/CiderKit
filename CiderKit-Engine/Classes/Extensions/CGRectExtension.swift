extension CGRect {
    
    init(center: CGPoint, size: CGSize) {
        let origin = CGPoint(x: center.x - (size.width * 0.5), y: center.y - (size.height * 0.5))
        self.init(origin: origin, size: size)
    }
    
}
