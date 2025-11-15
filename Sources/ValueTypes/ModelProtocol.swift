//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

/// Namespace for types used on Views
public struct Model {
    private init() {}
}

/// Base protocol for models used inside the app.
/// All models must be:
/// - Codable: persistable
/// - Hashable & Equatable: for collections and SwiftUI diffing
/// - CustomStringConvertible: convertible to String
public protocol ModelProtocol: Codable, Hashable, CustomStringConvertible {}

/// Models used on the UI layer
/// - Identifiable: needed by SwiftUI lists
public protocol ModelForViewProtocol: ModelProtocol, Identifiable {}

/// Provide a safe default `description` for all Models
public extension ModelProtocol {
    var description: String {
        String(describing: Self.self)
    }
}
