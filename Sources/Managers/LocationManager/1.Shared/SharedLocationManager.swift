//
//  SharedLocationManager.swift
//  Common
//
//  Created by Ricardo Santos on 28/08/2024.
//

import Foundation
import CoreLocation
import Combine

//
// MARK: - CoreLocationManager
//

public extension Common {
    class SharedLocationManager: NSObject {
        public static var shared = SharedLocationManager()
        @PWThreadSafe private var locationManager: CLLocationManager?
        @PWThreadSafe private static var lastAuthorizationStatus: CLAuthorizationStatus?
        @PWThreadSafe public private(set) static var lastKnowLocation: (coordinate: Common.LocationUtils.Coordinate, date: Date)?
        @PWThreadSafe private var onDidUpdateLocation: ((Common.LocationUtils.Coordinate?) -> Void)?
        @PWThreadSafe private var onLocationLost: (() -> Void)?
        @PWThreadSafe private var onLocationAuthorized: (() -> Void)?

        var lastKnowLocation: (coordinate: Common.LocationUtils.Coordinate, date: Date)? {
            Self.lastKnowLocation
        }

        var locationIsExplicitlyDenied: Bool {
            Self.lastAuthorizationStatus == .denied
        }

        var locationIsAuthorized: Bool {
            Self.lastAuthorizationStatus?.locationIsAuthorized ?? false
        }

        func startUpdatingLocation(
            onLocationAuthorized: @escaping (() -> Void),
            onDidUpdateLocation: @escaping ((Common.LocationUtils.Coordinate?) -> Void),
            onLocationLost: @escaping (() -> Void)
        ) {
            if isConfigured {
                if let locationIsAuthorized = Self.lastAuthorizationStatus?.locationIsAuthorized, locationIsAuthorized {
                    // If we are calling [startUpdatingLocation], and we have already
                    // configured, and we have authorisation's, then
                    // lets call the [onLocationAuthorized]
                    self.onLocationAuthorized?()
                    if let lastKnowLocation = lastKnowLocation?.coordinate {
                        onDidUpdateLocation(lastKnowLocation)
                    }
                }
            } else {
                self.onLocationAuthorized = onLocationAuthorized
                self.onDidUpdateLocation = onDidUpdateLocation
                self.onLocationLost = onLocationLost
            }
            evalAndPerformAccordingToLocationManagerStatus()
        }

        func resumeUpdatingLocation() {
            if !isConfigured {
                fatalError("Not configured. Use \(String(describing: startUpdatingLocation))")
            }
            evalAndPerformAccordingToLocationManagerStatus()
        }

        func stopUpdatingLocation() {
            onLocationLost?()
            onDidUpdateLocation?(nil)
            locationManager?.stopUpdatingLocation()
        }
    }
}

//
// MARK: - CLLocationManagerDelegate
//

extension Common.SharedLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let lastStatusWasAuthorized = Self.lastAuthorizationStatus?.locationIsAuthorized ?? false
        let newStatusIsAuthorized = status.locationIsAuthorized
        let newStatusIsNotAuthorized = !newStatusIsAuthorized
        Self.lastAuthorizationStatus = status
        if newStatusIsAuthorized {
            onLocationAuthorized?()
            evalAndPerformAccordingToLocationManagerStatus()
        } else if lastStatusWasAuthorized, newStatusIsNotAuthorized {
            stopUpdatingLocation()
            evalAndPerformAccordingToLocationManagerStatus()
        } else if status == .notDetermined {
            evalAndPerformAccordingToLocationManagerStatus()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let last: Common.LocationUtils.Coordinate = .init(location: location)
            Self.lastKnowLocation = (last, Date())
            onDidUpdateLocation?(last)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard !Common_Utils.onSimulator else {
            return
        }
    }
}

//
// MARK: - Private
//

fileprivate extension Common.SharedLocationManager {
    var isConfigured: Bool {
        if onDidUpdateLocation == nil || onLocationLost == nil || onLocationAuthorized == nil {
            return false
        }
        return true
    }

    func evalAndPerformAccordingToLocationManagerStatus() {
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }
        switch Self.lastAuthorizationStatus ?? .notDetermined {
        case .notDetermined:
            locationManager?.requestAlwaysAuthorization()
        case .restricted: // This application is not authorized to use location services.
            ()
        case .denied: // User has explicitly denied authorization for this application
            stopUpdatingLocation()
        case .authorizedAlways: // User has granted authorization to use their location at any time.
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.startUpdatingLocation()
        case .authorizedWhenInUse: // User has granted authorization to use their location only while they are using your app
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.startUpdatingLocation()
        @unknown default:
            ()
        }
    }
}

//
// MARK: - CLAuthorizationStatus extension
//

extension CLAuthorizationStatus {
    var locationIsAuthorized: Bool {
        switch self {
        case .authorizedAlways,
             .authorizedWhenInUse: true
        case .denied,
             .notDetermined,
             .restricted: false
        default: false
        }
    }
}

//
// MARK: - CLAuthorizationStatus extension
//
private extension Common.SharedLocationManager {
    static func sampleUsage() {
        Common.SharedLocationManager.shared.startUpdatingLocation {
            Common_Logs.debug("User location start updating")
        } onDidUpdateLocation: { location in
            if let location {
                Common_Logs.debug("User location updated to \(location)")
            } else {
                Common_Logs.debug("User location lost?")
            }
        } onLocationLost: {
            Common_Logs.debug("User location lost")
        }
    }
}
