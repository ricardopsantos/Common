//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
import CoreLocation
import Foundation

//

// MARK: - SharedLocationManagerViewModel

//
extension Common.SharedLocationManagerViewModel: Equatable {
    public static func == (
        lhs: Common.SharedLocationManagerViewModel,
        rhs: Common.SharedLocationManagerViewModel
    ) -> Bool {
        lhs.coordinates == rhs.coordinates &&
            lhs.locationIsAuthorized == rhs.locationIsAuthorized
    }
}

public extension Common {
    final class SharedLocationManagerViewModel: ObservableObject, LocationManagerViewModelProtocol {
        private init() {}
        public static var shared = SharedLocationManagerViewModel()
        @PWThreadSafe private var refCount: [String: Bool] = [:]
        @Published public private(set) var locationIsAuthorized: Bool = true

        //

        // MARK: - LocationManagerViewModelProtocol

        //
        @Published public var coordinates: Common.LocationUtils.Coordinate?
        public static var lastKnowLocation: (coordinate: LocationUtils.Coordinate, date: Date)?

        public func stop(sender: String) {
            if refCount[sender] != nil {
                refCount[sender] = false
            }
            let using = refCount.filter(\.value).map(\.key)
            if using.isEmpty {
                Common_Logs.debug("\(Self.self) stoped", "\(Self.self)")
                SharedLocationManager.shared.stopUpdatingLocation()
            } else {
                Common_Logs.debug("\(Self.self) stop by [\(sender)] ignored. On use by \(using)", "\(Self.self)")
            }
        }

        public func start(sender: String) {
            Common_Logs.debug("\(Self.self) started", "\(Self.self)")
            let onLocationLost = { [weak self] in
                self?.coordinates = nil
            }
            if refCount[sender] == nil {
                refCount[sender] = true
            }
            SharedLocationManager.shared.startUpdatingLocation { [weak self] in
                self?.locationIsAuthorized = SharedLocationManager.shared.locationIsAuthorized
            } onDidUpdateLocation: { [weak self] location in
                self?.locationIsAuthorized = SharedLocationManager.shared.locationIsAuthorized
                if let location {
                    Self.lastKnowLocation = SharedLocationManager.shared.lastKnowLocation
                    self?.coordinates = location
                } else {
                    onLocationLost()
                }
            } onLocationLost: { [weak self] in
                self?.locationIsAuthorized = SharedLocationManager.shared.locationIsAuthorized
                onLocationLost()
            }
        }
    }
}
