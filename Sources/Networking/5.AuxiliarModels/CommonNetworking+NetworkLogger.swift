//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation

public extension CommonNetworking {
    //

    // MARK: - NetworkLogger

    //
    struct NetworkLogger {
        public let dumpRequest: Bool
        public let dumpResponse: Bool
        public let logError: Bool
        public let logOperationTime: Bool
        public var prefix: String = ""
        public var number: Int

        public init(
            dumpRequest: Bool,
            dumpResponse: Bool,
            logError: Bool,
            logOperationTime: Bool,
            number: Int
        ) {
            self.dumpRequest = dumpRequest
            self.dumpResponse = dumpResponse
            self.logError = logError
            self.logOperationTime = logOperationTime
            self.number = number
        }
    }
}

public extension CommonNetworking.NetworkLogger {
    static var allOn: Self {
        Self(dumpRequest: true, dumpResponse: true, logError: true, logOperationTime: true, number: 0)
    }

    static var requestAndResponses: Self {
        Self(dumpRequest: true, dumpResponse: true, logError: true, logOperationTime: false, number: 0)
    }

    static var none: Self {
        allOff
    }

    static var allOff: Self {
        Self(dumpRequest: false, dumpResponse: false, logError: false, logOperationTime: false, number: 0)
    }
}
