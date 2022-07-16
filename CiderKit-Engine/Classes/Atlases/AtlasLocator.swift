public struct AtlasLocator {
    public let url: URL
    public let bundle: Bundle
    
    public init(url: URL, bundle: Bundle) {
        self.url = url
        self.bundle = bundle
    }
}
