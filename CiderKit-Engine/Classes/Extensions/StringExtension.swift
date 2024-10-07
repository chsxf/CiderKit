import CryptoKit

extension String {
    
    func toSHA256() -> String {
        let data = self.data(using: .utf8)!
        let digest = SHA256.hash(data: data)
        var compiledDigest = ""
        for i in digest {
            compiledDigest += String(format: "%02x", i)
        }
        return compiledDigest
    }
    
}
