//
//  CronometerManager+Extensions.swift
//  Common
//
//  Created by Ricardo Santos on 16/11/2025.
//

import Foundation

public extension URLRequest {
    var cronometerId: String {
        var id = ""
        if let method = httpMethod {
            id += method.uppercased()
        }
        if let urlStr = url?.absoluteString {
            id += "|\(urlStr)"
        }
        return id
    }
}
