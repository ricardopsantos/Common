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
    enum NetworkStatus: Equatable, Hashable, Sendable {
        case unknown
        case internetConnectionAvailable
        case internetConnectionRecovered
        case internetConnectionLost

        public var existsInternetConnection: Bool {
            switch self {
            case .internetConnectionAvailable, .internetConnectionRecovered:
                return true
            case .unknown, .internetConnectionLost:
                return false
            }
        }
    }

    @MainActor
    final class NetworkMonitorViewModel: ObservableObject {
        private static let networkMonitor = NetworkMonitor.shared
        public static let shared = NetworkMonitorViewModel()

        @Published public private(set) var networkStatus: NetworkStatus = .unknown

        private init() {
            networkStatus = Common_Utils.existsInternetConnection()
                ? .internetConnectionAvailable
                : .internetConnectionLost

            Self.networkMonitor.start { [weak self] newStatus in
                self?.networkStatus = newStatus
            }
        }
    }

    final class NetworkMonitor {
        public typealias Status = NetworkStatus
        public static let shared = NetworkMonitor()

        private let monitor = NWPathMonitor()
        private var lastStatus: Status?
        private var isInternetConnectionAvailable: Bool?

        private init() {
            monitor.start(queue: DispatchQueue(label: "\(Self.self).queue", qos: .userInitiated))
        }

        public func start(statusUpdate: @escaping (Status) -> Void) {
            monitor.pathUpdateHandler = { [weak self] path in
                guard let self else { return }

                let status: Status = {
                    if path.status == .satisfied {
                        // First ever update
                        if self.isInternetConnectionAvailable == nil {
                            return .internetConnectionAvailable
                        }
                        // Only "recovered" when transitioning from lost → available
                        return self.lastStatus == .internetConnectionLost
                            ? .internetConnectionRecovered
                            : .internetConnectionAvailable
                    } else {
                        return .internetConnectionLost
                    }
                }()

                // Prevent duplicate events
                guard status != lastStatus else { return }

                lastStatus = status
                isInternetConnectionAvailable = status.existsInternetConnection

                Common_Utils.executeInMainTread {
                    statusUpdate(status)
                }
            }
        }
    }
}
