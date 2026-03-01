//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import Foundation
import Network
#if !os(watchOS)
    import SystemConfiguration
#endif

// https://www.vadimbulavin.com/network-connectivity-on-ios-with-swift/

public extension CommonNetworking {
    struct Reachability {
        private init() {}

        // ---------------------------------------------------------------------

        // MARK: - Default Reachability Helper

        // ---------------------------------------------------------------------
        //
        // Creates a reachability reference pointing to "0.0.0.0".
        // This is the recommended approach for basic connectivity checks.
        //
        // SCNetworkReachability will evaluate whether the system has a valid
        // default route for outgoing network traffic.
        //
        private static var defaultReachability: SCNetworkReachability? {
            var zeroAddress = sockaddr_in()
            zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)

            return withUnsafePointer(to: &zeroAddress) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    SCNetworkReachabilityCreateWithAddress(nil, $0)
                }
            }
        }

        // ---------------------------------------------------------------------

        // MARK: - Public API

        // ---------------------------------------------------------------------

        public enum Method: Int {
            case v1 // Basic synchronous check
            case v2 // Improved synchronous check (recommended)
            case v3 // True internet connectivity using network request

            public static var `default`: Self { .v2 }
        }

        /// Entry point. Selects the method.
        public static func isConnectedToNetwork(_ method: Method) -> Bool {
            switch method {
            case .v1: return isConnectedToNetworkV1
            case .v2: return isConnectedToNetworkV2
            case .v3: return isConnectedToNetworkV3
            }
        }

        // ---------------------------------------------------------------------

        // MARK: - V1 — Basic Synchronous Reachability

        // ---------------------------------------------------------------------
        //
        // Uses a temporary sockaddr_in, obtains reachability flags,
        // and checks `.reachable` + !`.connectionRequired`.
        //
        private static var isConnectedToNetworkV1: Bool {
            var zeroAddress = sockaddr_in()
            zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)

            guard let reachability = withUnsafePointer(to: &zeroAddress, {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    SCNetworkReachabilityCreateWithAddress(nil, $0)
                }
            }) else {
                return false
            }

            var flags = SCNetworkReachabilityFlags()
            guard SCNetworkReachabilityGetFlags(reachability, &flags) else { return false }

            let reachable = flags.contains(.reachable)
            let needsConnection = flags.contains(.connectionRequired)

            return reachable && !needsConnection
        }

        // ---------------------------------------------------------------------

        // MARK: - V2 — Improved Synchronous Reachability (Recommended)

        // ---------------------------------------------------------------------
        //
        // Same concept as V1, but reuses a stable reachability reference.
        // Simpler, more readable, and avoids creating extra objects.
        //
        private static var isConnectedToNetworkV2: Bool {
            guard let reachability = defaultReachability else { return false }

            var flags = SCNetworkReachabilityFlags()
            guard SCNetworkReachabilityGetFlags(reachability, &flags) else { return false }

            let reachable = flags.contains(.reachable)
            let needsConnection = flags.contains(.connectionRequired)

            return reachable && !needsConnection
        }

        // ---------------------------------------------------------------------

        // MARK: - V3 — Real Internet Test

        // ---------------------------------------------------------------------
        //
        // Performs a real network request (Google).
        // Cached + throttled to max 1 request per second.
        // Safe parallel usage via a private serial queue.
        //
        @PWThreadSafe private static var isConnected = false
        @PWThreadSafe private static var isFetching = false
        @PWThreadSafe private static var lastRequestTime: Date?

        private static let lockQueue = DispatchQueue(label: "Reachability.V3.lockQueue")

        private static var isConnectedToNetworkV3: Bool {
            return lockQueue.sync {
                // Throttle repeated calls (cache result for 1 second)
                if let lastRequestTime,
                   Date().timeIntervalSince(lastRequestTime) < 1
                {
                    return isConnected
                }

                // Avoid duplicated concurrent requests
                if isFetching {
                    return isConnected
                }

                isFetching = true
                lastRequestTime = Date()

                let url = URL(string: "https://www.google.com")!
                let semaphore = DispatchSemaphore(value: 0)

                let task = URLSession.shared.dataTask(with: url) { _, response, error in

                    defer {
                        isFetching = false
                        semaphore.signal()
                    }

                    if error == nil,
                       let http = response as? HTTPURLResponse,
                       (200 ... 299).contains(http.statusCode)
                    {
                        isConnected = true
                    } else {
                        isConnected = false
                    }
                }

                task.resume()

                // Wait for max 1 second — if timeout, return cached result
                let waitResult = semaphore.wait(timeout: .now() + 1)

                if waitResult == .timedOut {
                    task.cancel()
                    isFetching = false
                }

                return isConnected
            }
        }
    }
}
