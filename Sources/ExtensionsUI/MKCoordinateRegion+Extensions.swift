//
//  MKCoordinateRegion+Extensions.swift
//  Common
//
//  Created by Ricardo Santos on 26/08/2024.
//

import MapKit

// MARK: - Equatable (Retroactive)

extension MKCoordinateRegion: @retroactive Equatable {
    /// Because doubles should not be compared exactly, we use a very small tolerance.
    private static func nearlyEqual(_ a: CLLocationDegrees, _ b: CLLocationDegrees, tolerance: Double = 1e-12) -> Bool {
        abs(a - b) < tolerance
    }

    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        nearlyEqual(lhs.center.latitude, rhs.center.latitude) &&
            nearlyEqual(lhs.center.longitude, rhs.center.longitude) &&
            nearlyEqual(lhs.span.latitudeDelta, rhs.span.latitudeDelta) &&
            nearlyEqual(lhs.span.longitudeDelta, rhs.span.longitudeDelta)
    }
}

// MARK: - Bounds Helpers

public extension MKCoordinateRegion {
    /// Maximum latitude contained in the region.
    var latitudeMax: CLLocationDegrees {
        center.latitude + span.latitudeDelta / 2
    }

    /// Minimum latitude contained in the region.
    var latitudeMin: CLLocationDegrees {
        center.latitude - span.latitudeDelta / 2
    }

    /// Maximum longitude contained in the region.
    var longitudeMax: CLLocationDegrees {
        center.longitude + span.longitudeDelta / 2
    }

    /// Minimum longitude contained in the region.
    var longitudeMin: CLLocationDegrees {
        center.longitude - span.longitudeDelta / 2
    }

    /// Tuple containing all region bounds.
    ///
    /// Naming matches your original definition.
    var latLongBounds: (
        latitudeMax: CLLocationDegrees,
        latitudeMin: CLLocationDegrees,
        longitudeMax: CLLocationDegrees,
        longitudeMin: CLLocationDegrees
    ) {
        (
            latitudeMax: latitudeMax,
            latitudeMin: latitudeMin,
            longitudeMax: longitudeMax,
            longitudeMin: longitudeMin
        )
    }
}
