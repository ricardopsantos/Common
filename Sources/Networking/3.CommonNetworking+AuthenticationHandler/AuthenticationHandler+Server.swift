//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos.
//

import CommonCrypto
import Foundation
import Security

public extension CommonNetworking.AuthenticationHandler {
    struct Server {
        public let url: String
        public let publicHashKeys: [String]
        public let pathToCertificates: [String]?
        public let credentials: (user: String, password: String)?

        public init(
            url: String,
            publicHashKeys: [String],
            credentials: (user: String, password: String)? = nil,
            pathToCertificates: [String]? = nil
        ) {
            self.url = url
            self.publicHashKeys = publicHashKeys
            self.credentials = credentials
            self.pathToCertificates = pathToCertificates
        }
    }
}

// MARK: - Predefined servers

public extension CommonNetworking.AuthenticationHandler.Server {
    static var gitHub: Self {
        Self(
            url: "https://gist.github.com/",
            publicHashKeys: ["XZVlvxBvEFhGF+9gt9WOwIJdvQBYT3Cqnu0mu6S884I="],
            pathToCertificates: []
        )
    }

    static var googleUkWithHashKeys: Self {
        Self(
            url: "https://www.google.co.uk/",
            publicHashKeys: ["caMXMXM6GkN65HHqWbN8rm32m0Td+FXeMwVaraqJies="],
            pathToCertificates: nil
        )
    }

    static var googleUkWithCertPath: Self {
        var paths: [String]?
        #if IN_PACKAGE_CODE
            paths = Bundle.module.path(forResource: "google.co.uk", ofType: "cer").map { [$0] }
        #else
            paths = Bundle.main.path(forResource: "google.co.uk", ofType: "cer").map { [$0] }
        #endif

        if paths == nil {
            fatalError("google.co.uk.cer not found")
        }

        return Self(
            url: "https://www.google.co.uk/",
            publicHashKeys: [],
            pathToCertificates: paths
        )
    }
}
