//
//  CLLocationCoordinate2D+Extensions.swift
//  Common
//
//  Created by Ricardo Santos on 24/08/2024.
//

import Foundation
import MapKit

// MARK: - Retroactive Conformance

extension CLLocationCoordinate2D: @retroactive Equatable {}
extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - Coordinates + Helpers

public extension CLLocationCoordinate2D {
    // --- Named city constants (unchanged) ---
    static var lisbon: Self { .init(latitude: 38.736946, longitude: -9.142685) }
    static var london: Self { .init(latitude: 51.507222, longitude: -0.1275) }
    static var paris: Self { .init(latitude: 48.856613, longitude: 2.352222) }
    static var berlin: Self { .init(latitude: 52.52, longitude: 13.405) }
    static var madrid: Self { .init(latitude: 40.416775, longitude: -3.70379) }
    static var rome: Self { .init(latitude: 41.902782, longitude: 12.496366) }
    static var amsterdam: Self { .init(latitude: 52.3676, longitude: 4.9041) }
    static var brussels: Self { .init(latitude: 50.850346, longitude: 4.351721) }
    static var vienna: Self { .init(latitude: 48.208174, longitude: 16.373819) }
    static var stockholm: Self { .init(latitude: 59.329323, longitude: 18.068581) }
    static var copenhagen: Self { .init(latitude: 55.676098, longitude: 12.568337) }
    static var athens: Self { .init(latitude: 37.98381, longitude: 23.727539) }
    static var dublin: Self { .init(latitude: 53.349805, longitude: -6.26031) }
    static var helsinki: Self { .init(latitude: 60.169856, longitude: 24.938379) }
    static var oslo: Self { .init(latitude: 59.913869, longitude: 10.752245) }
    static var warsaw: Self { .init(latitude: 52.229676, longitude: 21.012229) }
    static var prague: Self { .init(latitude: 50.075538, longitude: 14.4378) }
    static var budapest: Self { .init(latitude: 47.497912, longitude: 19.040235) }
    static var bucharest: Self { .init(latitude: 44.426767, longitude: 26.102538) }
    static var sofia: Self { .init(latitude: 42.697708, longitude: 23.321868) }
    static var moscow: Self { .init(latitude: 55.755826, longitude: 37.6173) }
    static var kyiv: Self { .init(latitude: 50.4501, longitude: 30.5234) }
    static var zurich: Self { .init(latitude: 47.376887, longitude: 8.541694) }

    static var europeanCapitals: [CLLocationCoordinate2D] {
        [
            .lisbon, .london, .paris, .berlin, .madrid, .rome, .amsterdam,
            .brussels, .vienna, .stockholm, .copenhagen, .athens, .dublin,
            .helsinki, .oslo, .warsaw, .prague, .budapest, .bucharest,
            .sofia, .moscow, .kyiv, .zurich,
        ]
    }

    // MARK: - Random coordinate utilities

    /// Random coordinate around Lisbon (50km)
    static var random: Self {
        random(in: 50000, around: .lisbon)
    }

    /// Generate a random coordinate in a radius around a center point.
    ///
    /// - Parameters:
    ///   - radius: radius in meters
    ///   - center: the central coordinate
    static func random(
        in radius: Double = 50000,
        around center: CLLocationCoordinate2D = .lisbon
    ) -> CLLocationCoordinate2D {
        let earthRadius = 6_371_000.0

        // Random angle + distance
        let angle = Double.random(in: 0 ..< 2 * .pi)
        let distance = Double.random(in: 0 ..< radius)

        // Convert distance to degrees latitude
        let deltaLat = (distance / earthRadius) * (180 / .pi)

        // Protect against high-latitude cos(φ) shrinkage
        let latRad = center.latitude * .pi / 180
        let cosLat = max(0.0001, cos(latRad)) // avoid divide-by-zero near poles

        let deltaLon = (distance / (earthRadius * cosLat)) * (180 / .pi)

        let latitude = center.latitude + deltaLat * cos(angle)
        let longitude = center.longitude + deltaLon * sin(angle)

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // MARK: - Region helper

    static func regionToFitCoordinates(
        coordinates: [CLLocationCoordinate2D],
        extraDelta: Double = 0.3
    ) -> MKCoordinateRegion {
        coordinates.regionToFitCoordinates(extraDelta: extraDelta)
    }
}

// MARK: - Array<Coordinate> helpers

public extension [CLLocationCoordinate2D] {
    /// Compute a region that fits all coordinates with optional padding.
    func regionToFitCoordinates(extraDelta: Double = 0.1) -> MKCoordinateRegion {
        guard !isEmpty else { return MKCoordinateRegion() }

        var minLat = self[0].latitude
        var maxLat = self[0].latitude
        var minLon = self[0].longitude
        var maxLon = self[0].longitude

        for coordinate in self {
            minLat = Swift.min(minLat, coordinate.latitude)
            maxLat = Swift.max(maxLat, coordinate.latitude)
            minLon = Swift.min(minLon, coordinate.longitude)
            maxLon = Swift.max(maxLon, coordinate.longitude)
        }

        // Expand region for padding
        var latDelta = maxLat - minLat
        var lonDelta = maxLon - minLon
        latDelta += extraDelta
        lonDelta += extraDelta

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        return MKCoordinateRegion(center: center, span: span)
    }
}
