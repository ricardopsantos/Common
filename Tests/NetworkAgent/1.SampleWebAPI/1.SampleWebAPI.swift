//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
@testable import Common
import Foundation

final class SampleWebAPI: CommonNetworking.NetworkAgentClient, NetworkAgentProtocol {
    public var client: CommonNetworking.NetworkAgentClient {
        CommonNetworking.NetworkAgentClient(session: urlSession)
    }

    #if targetEnvironment(simulator)
        public var defaultLogger: CommonNetworking.NetworkLogger { .requestAndResponses }
    #else
        public var defaultLogger: CommonNetworking.NetworkLogger { .allOff }
    #endif
}

extension SampleWebAPI {
    func performRequest<T: Decodable>(_ api: Methods)
        -> AnyPublisher<T, CommonNetworking.APIError>
    {
        let urlRequest = api.urlRequest
        //let cronometerId: String = #function + "." + urlRequest!.cronometerId
        //CronometerAverageMetrics.shared.start(key: cronometerId)
        return requestPublisher(request: urlRequest!,
                                decoder: .defaultForWebAPI,
                                logger: .allOn,
                                responseType: .json,
                                onCompleted: {
                                //    CronometerAverageMetrics.shared.start(key: cronometerId)
                                })
    }


}
