//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

@testable import Common
import Foundation

extension SampleWebAPI {
    enum RequestModel {
        struct Employee: Codable {
            public let id: String
            public init(id: String) {
                self.id = id
            }
        }

        struct Pinning {
            public let url: String
            public init(url: String) {
                self.url = url
            }
        }
    }
}
