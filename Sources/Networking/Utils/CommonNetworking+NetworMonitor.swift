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
            networkStatus = Common_Utils
                .existsInternetConnection() ? .internetConnectionAvailable : .internetConnectionLost
            Self.networkMonitor.start { [weak self] newStatus in
                self?.networkStatus = newStatus
            }
        }
    }

    final class NetworkMonitor {
        public typealias Status = NetworkStatus
        public static let shared = NetworkMonitor()

        private var monitor: NWPathMonitor!
        private var isInternetConnectionAvailable: Bool?
        private var statusHistory = [Status]()

        private init() {
            monitor = NWPathMonitor()
            monitor.start(queue: DispatchQueue(label: "\(Self.self).queue", qos: .userInitiated))
        }

        public func start(statusUpdate: @escaping (Status) -> Void) {
            monitor.pathUpdateHandler = { [weak self] path in
                Common_Utils.executeInMainTread { [weak self] in
                    guard let self else { return }
                    let newStatus: Status = if path.status == .satisfied {
                        if isInternetConnectionAvailable == nil {
                            .internetConnectionAvailable
                        } else {
                            .internetConnectionRecovered
                        }
                    } else {
                        .internetConnectionLost
                    }

                    if statusHistory.last != newStatus {
                        statusHistory.append(newStatus)
                        statusUpdate(newStatus)
                        isInternetConnectionAvailable = newStatus.existsInternetConnection
                    }
                }
            }
        }
    }
}
