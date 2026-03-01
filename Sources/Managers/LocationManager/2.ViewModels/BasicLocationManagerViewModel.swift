//
//  BasicLocationManagerViewModel.swift
//  Common
//
//  Created by Ricardo Santos on 28/08/2024.
//

import CoreLocation
import Foundation

//

// MARK: - BasicLocationManagerViewModel

//

public extension Common {
    final class BasicLocationManagerViewModel: NSObject, ObservableObject, LocationManagerViewModelProtocol {
        @PWThreadSafe private var refCount: [String: Bool] = [:]

        private let locationManager = CLLocationManager()
        override public init() {
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
        }

        //

        // MARK: - LocationManagerViewModelProtocol

        //
        @Published public var coordinates: LocationUtils.Coordinate?
        public static var lastKnowLocation: (
            coordinate: LocationUtils.Coordinate,
            date: Date
        )?
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
            if refCount[sender] == nil {
                refCount[sender] = true
            }
            locationManager.startUpdatingLocation()
        }
    }
}

//

// MARK: - CLLocationManagerDelegate

//

extension Common.BasicLocationManagerViewModel: CLLocationManagerDelegate {
    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        coordinates = .init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        if let coordinates {
            Common.BasicLocationManagerViewModel.lastKnowLocation = (coordinates, Date())
        }
    }
}
