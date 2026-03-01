//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

/// Namespace for all Web API Request DTOs
public struct RequestDto {
    private init() {}
}

/// Shared protocol for all request DTO types.
/// - Codable: for JSON encode/decode
/// - Hashable: stored in sets/dictionaries, ensures value semantics
/// - CustomStringConvertible: for logging/debugging
public protocol RequestDtoProtocol: Codable, Hashable, CustomStringConvertible {}

/// Default description = type name
public extension RequestDtoProtocol {
    var description: String {
        String(describing: Self.self)
    }
}
