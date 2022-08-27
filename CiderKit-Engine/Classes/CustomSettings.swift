import Foundation

public struct CustomSettings: Codable {
    
    enum CodingKeys : String, CodingKey {
        case bools = "b"
        case ints = "i"
        case floats = "f"
        case doubles = "d"
        case strings = "s"
    }
    
    struct CustomCodingKey: CodingKey {
        
        var stringValue: String
        
        init!(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        var intValue: Int?
        
        init!(intValue: Int) {
            self.stringValue = ""
            self.intValue = intValue
        }
        
    }
    
    private var boolSettings: [String: Bool]? = nil
    private var intSettings: [String: Int]? = nil
    private var floatSettings: [String: Float]? = nil
    private var doubleSettings: [String: Double]? = nil
    private var stringSettings: [String: String]? = nil
    
    public init() {
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(CodingKeys.bools) {
            let boolContainer = try container.nestedContainer(keyedBy: CustomCodingKey.self, forKey: .bools)
            if !boolContainer.allKeys.isEmpty {
                boolSettings = [String: Bool]()
                for key in boolContainer.allKeys {
                    boolSettings![key.stringValue] = try boolContainer.decode(Bool.self, forKey: key)
                }
            }
        }
        
        if container.contains(CodingKeys.ints) {
            let intContainer = try container.nestedContainer(keyedBy: CustomCodingKey.self, forKey: .ints)
            if !intContainer.allKeys.isEmpty {
                intSettings = [String: Int]()
                for key in intContainer.allKeys {
                    intSettings![key.stringValue] = try intContainer.decode(Int.self, forKey: key)
                }
            }
        }
        
        if container.contains(CodingKeys.floats) {
            let floatContainer = try container.nestedContainer(keyedBy: CustomCodingKey.self, forKey: .floats)
            if !floatContainer.allKeys.isEmpty {
                floatSettings = [String: Float]()
                for key in floatContainer.allKeys {
                    floatSettings![key.stringValue] = try floatContainer.decode(Float.self, forKey: key)
                }
            }
        }
        
        if container.contains(CodingKeys.doubles) {
            let doubleContainer = try container.nestedContainer(keyedBy: CustomCodingKey.self, forKey: .doubles)
            if !doubleContainer.allKeys.isEmpty {
                doubleSettings = [String: Double]()
                for key in doubleContainer.allKeys {
                    doubleSettings![key.stringValue] = try doubleContainer.decode(Double.self, forKey: key)
                }
            }
        }
        
        if container.contains(CodingKeys.strings) {
            let stringContainer = try container.nestedContainer(keyedBy: CustomCodingKey.self, forKey: .strings)
            if !stringContainer.allKeys.isEmpty {
                stringSettings = [String: String]()
                for key in stringContainer.allKeys {
                    stringSettings![key.stringValue] = try stringContainer.decode(String.self, forKey: key)
                }
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let boolSettings = boolSettings {
            var boolContainer = container.nestedContainer(keyedBy: CustomCodingKey.self, forKey: .bools)
            for (key, value) in boolSettings {
                try boolContainer.encode(value, forKey: CustomCodingKey(stringValue: key))
            }
        }

        if let intSettings = intSettings {
            var intContainer = container.nestedContainer(keyedBy: CustomCodingKey.self, forKey: .ints)
            for (key, value) in intSettings {
                try intContainer.encode(value, forKey: CustomCodingKey(stringValue: key))
            }
        }
        
        if let floatSettings = floatSettings {
            var floatContainer = container.nestedContainer(keyedBy: CustomCodingKey.self, forKey: .floats)
            for (key, value) in floatSettings {
                try floatContainer.encode(value, forKey: CustomCodingKey(stringValue: key))
            }
        }
        
        if let doubleSettings = doubleSettings {
            var doubleContainer = container.nestedContainer(keyedBy: CustomCodingKey.self, forKey: .doubles)
            for (key, value) in doubleSettings {
                try doubleContainer.encode(value, forKey: CustomCodingKey(stringValue: key))
            }
        }
        
        if let stringSettings = stringSettings {
            var stringContainer = container.nestedContainer(keyedBy: CustomCodingKey.self, forKey: .strings)
            for (key, value) in stringSettings {
                try stringContainer.encode(value, forKey: CustomCodingKey(stringValue: key))
            }
        }
    }
    
    public func has(key: String) -> Bool {
        return hasBool(for: key) || hasInt(for: key) || hasFloat(for: key) || hasDouble(for: key) || hasString(for: key)
    }

    public mutating func clear() {
        boolSettings = nil
        intSettings = nil
        floatSettings = nil
        doubleSettings = nil
        stringSettings = nil
    }
    
    public mutating func remove(key: String) {
        if var boolSettings = boolSettings {
            boolSettings[key] = nil
        }
        if var intSettings = intSettings {
            intSettings[key] = nil
        }
        if var floatSettings = floatSettings {
            floatSettings[key] = nil
        }
        if var doubleSettings = doubleSettings {
            doubleSettings[key] = nil
        }
        if var stringSettings = stringSettings {
            stringSettings[key] = nil
        }
    }
    
    public mutating func setBool(for key: String, with value: Bool) {
        if has(key: key) && !hasBool(for: key) {
            remove(key: key)
        }
        boolSettings = boolSettings ?? [String:Bool]()
        boolSettings![key] = value
    }
    
    public func getBool(for key: String) -> Bool? {
        return boolSettings?[key]
    }
    
    public func hasBool(for key: String) -> Bool {
        guard let _ = boolSettings?[key] else {
            return false
        }
        return true
    }
    
    public mutating func setInt(for key: String, with value: Int) {
        if has(key: key) && !hasInt(for: key) {
            remove(key: key)
        }
        intSettings = intSettings ?? [String:Int]()
        intSettings![key] = value
    }
    
    public func getInt(for key: String) -> Int? {
        return intSettings?[key]
    }
    
    public func hasInt(for key: String) -> Bool {
        guard let _ = intSettings?[key] else {
            return false
        }
        return true
    }
    
    public mutating func setFloat(for key: String, with value: Float) {
        if has(key: key) && !hasFloat(for: key) {
            remove(key: key)
        }
        floatSettings = floatSettings ?? [String:Float]()
        floatSettings![key] = value
    }
    
    public func getFloat(for key: String) -> Float? {
        return floatSettings?[key]
    }
    
    public func hasFloat(for key: String) -> Bool {
        guard let _ = floatSettings?[key] else {
            return false
        }
        return true
    }
    
    public mutating func setDouble(for key: String, with value: Double) {
        if has(key: key) && !hasDouble(for: key) {
            remove(key: key)
        }
        doubleSettings = doubleSettings ?? [String:Double]()
        doubleSettings![key] = value
    }
    
    public func getDouble(for key: String) -> Double? {
        return doubleSettings?[key]
    }
    
    public func hasDouble(for key: String) -> Bool {
        guard let _ = doubleSettings?[key] else {
            return false
        }
        return true
    }
    
    public mutating func setString(for key: String, with value: String) {
        if has(key: key) && !hasString(for: key) {
            remove(key: key)
        }
        stringSettings = stringSettings ?? [String:String]()
        stringSettings![key] = value
    }
    
    public func getString(for key: String) -> String? {
        return stringSettings?[key]
    }
    
    public func hasString(for key: String) -> Bool {
        guard let _ = stringSettings?[key] else {
            return false
        }
        return true
    }
    
}
