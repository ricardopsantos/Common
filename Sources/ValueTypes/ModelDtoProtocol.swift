//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

/// Encapsulate all Data Transfer Objects (API request/response models)
public struct ModelDto {
    private init() {}
}

/// Common protocol for all DTO models
public protocol ModelDtoProtocol: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {}

/// Allow simple String to be used as a DTO
extension String: ModelDtoProtocol {
    public var description: String { self }
}

/// Allow Arrays of Strings to act as a DTO type
extension [String]: ModelDtoProtocol {

    /// Custom string formatting
    public var description: String {
        "[" + joined(separator: ", ") + "]"
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []

        while !container.isAtEnd {
            let element = try container.decode(Element.self)
            elements.append(element)
        }

        self = elements
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for element in self {
            try container.encode(element)
        }
    }

    // MARK: - Equatable

    public static func == (lhs: [Element], rhs: [Element]) -> Bool {
        lhs.elementsEqual(rhs)
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        for element in self {
            hasher.combine(element)
        }
    }
}
