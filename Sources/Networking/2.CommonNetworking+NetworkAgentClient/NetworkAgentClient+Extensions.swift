//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos.
//

import Combine
import Foundation
import Security

public extension CommonNetworking.NetworkAgentClient {
    func requestPublisher<T: Decodable>(
        request: URLRequest,
        decoder: JSONDecoder,
        logger: CommonNetworking.NetworkLogger,
        responseFormat: CommonNetworking.ResponseFormat
    ) -> AnyPublisher<CommonNetworking.Response<T>, CommonNetworking.APIError> {
        let cronometerId = request.cronometerId
        let requestDebug = "\(request) -> \(T.self)"
        let prefix = logger.prefix.isEmpty ? "" : "\(logger.prefix): "
        let suffix = logger.number > 0 ? " #\(logger.number)" : ""

        // Connectivity hint (non-blocking)
        if !Common_Utils.existsInternetConnection() {
            Common_Logs.error("⤴️ Request\(suffix) ⤴️ \(prefix)\(request) : No Internet connection", "\(Self.self)")
        }

        return urlSession
            .dataTaskPublisher(for: request)
            .handleEvents(receiveSubscription: { _ in
                if logger.logOperationTime {
                    Common_CronometerManager.startTimerWith(identifier: cronometerId)
                }
                if logger.dumpRequest {
                    Common_Logs.debug("⤴️ Request\(suffix) ⤴️ \(prefix)\(request)", "\(Self.self)")
                    request.curlCommand(doPrint: true)
                }
            })
            .tryMap { result -> CommonNetworking.Response<T> in

                defer {
                    if logger.logOperationTime {
                        Common_CronometerManager.timeElapsed(cronometerId, print: true)
                    }
                }

                // -----------------------------

                // MARK: - Status / Metadata

                // -----------------------------
                let data = result.data
                let statusCode = (result.response as? HTTPURLResponse)?.statusCode ?? -1
                let httpStatus = CommonNetworking.HTTPStatusCode(rawValue: statusCode) ?? .unknown
                let isEmpty = data.isEmpty
                let is204 = statusCode == 204
                let is205 = statusCode == 205

                // Dump response
                if logger.dumpResponse {
                    let bodyString = String(decoding: data, as: UTF8.self)
                    Common_Logs.debug("""
                    ⤵️ Response\(suffix)
                    Status: \(statusCode) \(httpStatus)
                    \(prefix)[\(requestDebug)]
                    \(bodyString)
                    """, "\(Self.self)")
                }

                // ------------------------------------------

                // MARK: - Non-success status → FAIL

                // ------------------------------------------
                guard httpStatus.isSuccess else {
                    throw CommonNetworking.APIError.finishWithStatusCodeAndJSONData(
                        code: statusCode,
                        description: nil,
                        data: data,
                        jsonString: data.jsonString
                    )
                }

                // ------------------------------------------

                // MARK: - EMPTY BODY HANDLING (DELETE/204/205)

                // ------------------------------------------
                if isEmpty || is204 || is205 {
                    // Case 1: Caller expects `Void` → OK
                    if T.self == Void.self {
                        return CommonNetworking.Response(
                            model: () as! T,
                            rawResponse: result.response
                        )
                    }

                    // Case 2: Caller expected body but server returned none → FAIL
                    throw CommonNetworking.APIError.finishWithStatusCodeAndJSONData(
                        code: statusCode,
                        description: """
                        Server returned empty body for status \(statusCode), \
                        but expected a \(T.self) body.
                        """,
                        data: data,
                        jsonString: nil
                    )
                }

                // ------------------------------------------

                // MARK: - Decode JSON / CSV

                // ------------------------------------------
                do {
                    let decoded: T
                    switch responseFormat {
                    case .json:
                        decoded = try decoder.decodeFriendly(T.self, from: data, printError: true)

                    case .csv:
                        let jsonConverted = try CommonNetworking.ParsingUtils.parseCSV(data: data)
                        decoded = try decoder.decodeFriendly(T.self, from: jsonConverted)
                    }

                    return CommonNetworking.Response(
                        model: decoded,
                        rawResponse: result.response
                    )

                } catch {
                    throw CommonNetworking.APIError.finishWithStatusCodeAndJSONData(
                        code: statusCode,
                        description: "Failed decoding \(T.self): \(error.localizedDescription)",
                        data: data,
                        jsonString: data.jsonString
                    )
                }
            }
            .mapError { error in
                if let api = error as? CommonNetworking.APIError { return api }
                return .underlying(error)
            }
            .eraseToAnyPublisher()
    }
}
