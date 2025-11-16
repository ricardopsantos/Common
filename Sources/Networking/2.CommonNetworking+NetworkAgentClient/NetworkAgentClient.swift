//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos.
//

import Combine
import Foundation
import Security

public extension CommonNetworking {
    /// NetworkAgentClient centralizes URLSession creation with optional authentication / SSL pinning.
    ///
    /// It acts as a lightweight wrapper around URLSession, ensuring that:
    ///  - AuthenticationHandler is used when needed
    ///  - URLSessionDelegate callbacks execute in a controlled queue
    ///  - Multiple init paths remain consistent and safe
    ///
    /// NOTE: This class does **not** enforce a specific session type (default/ephemeral/background),
    ///       it simply reuses the provided configuration.
    class NetworkAgentClient: NSObject, URLSessionDelegate {
        // MARK: - Stored Properties

        /// The underlying URLSession used for all networking.
        public let urlSession: URLSession

        /// Authentication handler retained only if needed
        private let authenticationHandler: CommonNetworking.AuthenticationHandler?

        /// Queue for delegate callbacks (serial for security-sensitive delegate calls)
        private static let delegateQueue: OperationQueue = {
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            queue.qualityOfService = .userInitiated
            queue.name = "\(CommonNetworking.self).\(NetworkAgentClient.self).queue"
            return queue
        }()

        // MARK: - Initializers

        /// No authentication at all.
        ///
        /// - Important:
        ///   Even without authentication, we still point the URLSession *delegate* to self
        ///   so the client can expand behaviors later (logging, retry, metrics, etc).
        public init(session: URLSession) {
            authenticationHandler = nil
            urlSession = URLSession(
                configuration: session.configuration, // use the SAME configuration but a fresh session
                delegate: nil,
                delegateQueue: Self.delegateQueue
            )

            super.init()
        }

        /// Basic authentication with username + password.
        public init(
            session: URLSession,
            credential: URLCredential
        ) {
            let handler = CommonNetworking.AuthenticationHandler(credential: credential)
            authenticationHandler = handler

            urlSession = URLSession(
                configuration: session.configuration,
                delegate: handler,
                delegateQueue: Self.delegateQueue
            )
            super.init()
        }

        /// SSL Pinning — Using Public Key Hashes.
        public init(
            session: URLSession,
            serverPublicHashKeys: [String]
        ) {
            let handler = CommonNetworking.AuthenticationHandler(serverPublicHashKeys: serverPublicHashKeys)
            authenticationHandler = handler

            urlSession = URLSession(
                configuration: session.configuration,
                delegate: handler,
                delegateQueue: Self.delegateQueue
            )
            super.init()
        }

        /// SSL Pinning — Using local certificate files.
        public init(
            session: URLSession,
            pathToCertificates: [String]
        ) {
            let handler = CommonNetworking.AuthenticationHandler(pathToCertificates: pathToCertificates)
            authenticationHandler = handler

            urlSession = URLSession(
                configuration: session.configuration,
                delegate: handler,
                delegateQueue: Self.delegateQueue
            )
            super.init()
        }

        // MARK: - Convenience Initializers

        /// Convenience initializer for `.default` URLSessionConfiguration
        override public convenience init() {
            self.init(session: URLSession(configuration: .default))
        }

        /// Ephemeral session (no caching, no disk writes)
        public static func ephemeral(
            credential: URLCredential? = nil,
            publicKeyPins: [String]? = nil,
            certPaths: [String]? = nil
        ) -> NetworkAgentClient {
            let session = URLSession(configuration: .ephemeral)

            if let credential {
                return .init(session: session, credential: credential)
            } else if let publicKeyPins {
                return .init(session: session, serverPublicHashKeys: publicKeyPins)
            } else if let certPaths {
                return .init(session: session, pathToCertificates: certPaths)
            } else {
                return .init(session: session)
            }
        }

        /// Background session convenience
        public static func background(
            identifier: String,
            credential: URLCredential? = nil,
            publicKeyPins: [String]? = nil,
            certPaths: [String]? = nil
        ) -> NetworkAgentClient {
            let config = URLSessionConfiguration.background(withIdentifier: identifier)
            let session = URLSession(configuration: config)

            if let credential {
                return .init(session: session, credential: credential)
            } else if let publicKeyPins {
                return .init(session: session, serverPublicHashKeys: publicKeyPins)
            } else if let certPaths {
                return .init(session: session, pathToCertificates: certPaths)
            } else {
                return .init(session: session)
            }
        }
    }
}
