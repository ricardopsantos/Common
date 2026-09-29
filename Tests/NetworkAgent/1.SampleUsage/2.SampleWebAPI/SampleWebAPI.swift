//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import Combine
@testable import Common

/// Legacy (pre-refactor) client, kept only for the legacy `2.Tests/SampleWebAPI_Tests.swift`
/// suite. Renamed to avoid colliding with the modern `SampleWebAPI` in `1.SampleWebAPI/`.
public class SampleWebAPILegacy: CommonNetworking.NetworkAgentClient, NetworkAgentProtocol {
    // `NetworkAgentProtocol.client` requires `CommonNetworking.NetworkAgent`, a different
    // type from `NetworkAgentClient` (which this class subclasses for `run`/`runAsync`,
    // used directly below instead of going through `client`). Only present to satisfy
    // the protocol requirement.
    public var client: CommonNetworking.NetworkAgent {
        CommonNetworking.NetworkAgent(session: urlSession)
    }

    #if targetEnvironment(simulator)
    public var defaultLogger: CommonNetworking.NetworkLogger { .requestAndResponses }
    #else
    public var defaultLogger: CommonNetworking.NetworkLogger { .allOff }
    #endif
}
