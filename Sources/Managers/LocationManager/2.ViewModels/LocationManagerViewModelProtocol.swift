//
//  LocationManagerViewModelProtocol.swift
//  Common
//
//  Created by Ricardo Santos on 28/08/2024.
//

import Foundation

public protocol LocationManagerViewModelProtocol {
    var coordinates: Common.LocationUtils.Coordinate? { get set }
    static var lastKnowLocation: (coordinate: Common.LocationUtils.Coordinate, date: Date)? { get set }
    func start(sender: String)
    func stop(sender: String)
}
