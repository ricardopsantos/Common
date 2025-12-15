//
//  1.NetworkAgentProtocol.swift
//  Created by Ricardo Santos
//

import Combine
import Foundation

public protocol NetworkAgentProtocol {
    var client: CommonNetworking.NetworkAgent { get }
    var defaultLogger: CommonNetworking.NetworkLogger { get }

    /// Combine: Executes a request and returns decoded model + raw response.
    func requestPublisher<T: Decodable>(
        request: URLRequest,
        decoder: JSONDecoder,
        logger: CommonNetworking.NetworkLogger,
        responseType: CommonNetworking.ResponseFormat,
        onCompleted: @escaping () -> Void
    ) -> AnyPublisher<CommonNetworking.Response<T>, CommonNetworking.APIError>

    /// Combine: Executes a request and returns only the decoded model.
    func requestPublisher<T: Decodable>(
        request: URLRequest,
        decoder: JSONDecoder,
        logger: CommonNetworking.NetworkLogger,
        responseType: CommonNetworking.ResponseFormat,
        onCompleted: @escaping () -> Void
    ) -> AnyPublisher<T, CommonNetworking.APIError>

    /// Combine: Executes request and returns only the raw URLResponse.
    func requestPublisher(
        request: URLRequest,
        decoder: JSONDecoder,
        logger: CommonNetworking.NetworkLogger,
        responseType: CommonNetworking.ResponseFormat,
        onCompleted: @escaping () -> Void
    ) -> AnyPublisher<URLResponse, CommonNetworking.APIError>

    /// async/await version returning decoded model only.
    func requestAsync<T: Decodable>(
        request: URLRequest,
        decoder: JSONDecoder,
        logger: CommonNetworking.NetworkLogger,
        responseType: CommonNetworking.ResponseFormat,
        onCompleted: @escaping () -> Void
    ) async throws -> T
}

// MARK: - Default Implementations

public extension NetworkAgentProtocol {
    // MARK: 1. Combine — Full response (model + raw URLResponse)

    ///
    /// Useful when consumer needs HTTP status code or headers.
    ///
    func requestPublisher<T: Decodable>(
        request: URLRequest,
        decoder: JSONDecoder = .defaultForWebAPI,
        logger: CommonNetworking.NetworkLogger,
        responseType: CommonNetworking.ResponseFormat,
        onCompleted: @escaping () -> Void
    ) -> AnyPublisher<CommonNetworking.Response<T>, CommonNetworking.APIError> {
        client.requestPublisher(
            request: request,
            decoder: decoder,
            logger: logger,
            responseFormat: responseType
        )
        .runBlockAndContinue { _ in onCompleted() } // Always notify caller
        .eraseToAnyPublisher()
    }

    // MARK: 2. Combine — Model only

    ///
    /// Most common case: just want decoded model → T.
    ///
    func requestPublisher<T: Decodable>(
        request: URLRequest,
        decoder: JSONDecoder = .defaultForWebAPI,
        logger: CommonNetworking.NetworkLogger,
        responseType: CommonNetworking.ResponseFormat,
        onCompleted: @escaping () -> Void
    ) -> AnyPublisher<T, CommonNetworking.APIError> {
        client.requestPublisher(
            request: request,
            decoder: decoder,
            logger: logger,
            responseFormat: responseType
        )
        .runBlockAndContinue { _ in onCompleted() }
        .map(\.model) // Extract decoded model
        .eraseToAnyPublisher()
    }

    // MARK: 3. Combine — Raw URLResponse only

    ///
    /// Useful when caller wants:
    /// - HTTP status code
    /// - headers
    /// - BUT does not care about body/data
    ///
    func requestPublisher(
        request: URLRequest,
        decoder: JSONDecoder = .defaultForWebAPI,
        logger: CommonNetworking.NetworkLogger,
        responseType: CommonNetworking.ResponseFormat,
        onCompleted: @escaping () -> Void
    ) -> AnyPublisher<URLResponse, CommonNetworking.APIError> {
        // Force T = EmptyDecodable
        let responsePublisher:
            AnyPublisher<CommonNetworking.Response<CommonNetworking.EmptyDecodable>,
                CommonNetworking.APIError> =
            client.requestPublisher(
                request: request,
                decoder: decoder,
                logger: logger,
                responseFormat: responseType
            )

        return responsePublisher
            .runBlockAndContinue { _ in onCompleted() }
            .map(\.rawResponse) // Extract only the URLResponse
            .eraseToAnyPublisher()
    }

    // MARK: 4. async/await — Model only

    ///
    /// Bridged version of the Combine pipeline.
    ///
    func requestAsync<T: Decodable>(
        request: URLRequest,
        decoder: JSONDecoder = .defaultForWebAPI,
        logger: CommonNetworking.NetworkLogger,
        responseType: CommonNetworking.ResponseFormat,
        onCompleted: @escaping () -> Void
    ) async throws -> T {
        defer { onCompleted() } // Guarantee exactly once

        let publisher: AnyPublisher<T, CommonNetworking.APIError> =
            client.requestPublisher(
                request: request,
                decoder: decoder,
                logger: logger,
                responseFormat: responseType
            )
            .map(\.model)
            .eraseToAnyPublisher()

        return try await publisher.async()
    }
}
