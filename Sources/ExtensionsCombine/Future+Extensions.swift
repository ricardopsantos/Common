//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation
import UIKit

/**
 https://swiftbysundell.com/articles/creating-combine-compatible-versions-of-async-await-apis/

 Usage:
 ```
 Future {
    try await self.loadModel(from: url)
 }
 ```
 */

public extension Future where Failure == Error {
    /// Creates a Combine Future from an async throwing operation.
    ///
    /// The async operation is executed inside a separate `Task`.
    /// Execution begins immediately when the Future is subscribed to.
    ///
    /// - Parameter operation: An async throwing function producing the output.
    convenience init(operation: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                do {
                    let output = try await operation()
                    promise(.success(output))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
