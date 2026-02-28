import Foundation

/// A lightweight type-erased Codable wrapper that supports the JSON primitive
/// types produced by the KarnEvil9 API: String, Int, Double, Bool, arrays,
/// dictionaries, and null.
struct AnyCodable: Codable, Equatable {

    let value: Any?

    // MARK: - Initializers

    init(_ value: Any?) {
        self.value = value
    }

    // MARK: - Convenience Accessors

    var stringValue: String? {
        value as? String
    }

    var intValue: Int? {
        if let intVal = value as? Int { return intVal }
        if let doubleVal = value as? Double { return Int(exactly: doubleVal) }
        return nil
    }

    var doubleValue: Double? {
        if let doubleVal = value as? Double { return doubleVal }
        if let intVal = value as? Int { return Double(intVal) }
        return nil
    }

    var boolValue: Bool? {
        value as? Bool
    }

    var arrayValue: [AnyCodable]? {
        value as? [AnyCodable]
    }

    var dictionaryValue: [String: AnyCodable]? {
        value as? [String: AnyCodable]
    }

    var isNil: Bool {
        value == nil
    }

    // MARK: - Decodable

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = nil
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable cannot decode value"
            )
        }
    }

    // MARK: - Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        guard let value = value else {
            try container.encodeNil()
            return
        }

        switch value {
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrayVal as [AnyCodable]:
            try container.encode(arrayVal)
        case let dictVal as [String: AnyCodable]:
            try container.encode(dictVal)
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "AnyCodable cannot encode value of type \(type(of: value))"
                )
            )
        }
    }

    // MARK: - Equatable

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (nil, nil):
            return true
        case (let l as Bool, let r as Bool):
            return l == r
        case (let l as Int, let r as Int):
            return l == r
        case (let l as Double, let r as Double):
            return l == r
        case (let l as String, let r as String):
            return l == r
        case (let l as [AnyCodable], let r as [AnyCodable]):
            return l == r
        case (let l as [String: AnyCodable], let r as [String: AnyCodable]):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - ExpressibleBy Literals

extension AnyCodable: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self.init(nil)
    }
}

extension AnyCodable: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: AnyCodable...) {
        self.init(elements)
    }
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, AnyCodable)...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}
