//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos.
//

import CommonCrypto
import Foundation
import Security

//
// https://medium.com/@anuj.rai2489/ssl-pinning-254fa8ca2109
// https://medium.com/@gizemturker/lock-down-your-app-with-https-and-certificate-pinning-a-swift-security-masterclass-d709494649bd
// https://www.ssllabs.com/ssltest/analyze.html
// https://www.ssldragon.com/blog/certificate-pinning/
//

/**
 __Static SSL Pinning:__ The SSL certificate is hard-coded into the application.
 If the certificate expires or is replaced → the app must be updated.

 __Dynamic SSL Pinning:__ A more flexible method that allows certificates or keys to be updated
 during runtime without shipping a new app version.
 */

/**
 # Certificate generation (example):

 1) Generate RSA private key
    `openssl genrsa -out google.key 2048`

 2) Create CSR
    `openssl req -new -key google.key -out google.csr`

 3) Create self-signed certificate
    `openssl x509 -req -days 365 -in google.csr -signkey google.key -out google.cert`
 */

// MARK: - AuthenticationHandler

public extension CommonNetworking {
    class AuthenticationHandler: NSObject, URLSessionDelegate {
        private let credential: URLCredential?
        private let serverPublicHashKeys: [String]?
        private let pathToCertificates: [String]?

        public init(server: Server) {
            if let c = server.credentials {
                credential = URLCredential(user: c.user, password: c.password, persistence: .forSession)
            } else {
                credential = nil
            }
            serverPublicHashKeys = server.publicHashKeys
            pathToCertificates = server.pathToCertificates
            super.init()
        }

        public init(credential: URLCredential) {
            self.credential = credential
            serverPublicHashKeys = nil
            pathToCertificates = nil
            super.init()
        }

        public init(serverPublicHashKeys: [String]) {
            credential = nil
            self.serverPublicHashKeys = serverPublicHashKeys
            pathToCertificates = nil
            super.init()
        }

        public init(pathToCertificates: [String]) {
            credential = nil
            serverPublicHashKeys = nil
            self.pathToCertificates = pathToCertificates
            super.init()
        }

        // MARK: - Challenge handler

        public func urlSession(
            _: URLSession,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            Common_Logs.debug("Received URLAuthenticationChallenge", "\(Self.self)")

            // -------------------------------------------
            // HTTP Basic Auth (first priority)
            // -------------------------------------------
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
                guard let credential else {
                    Common_Logs.error("No credentials for HTTP Basic Auth", "\(Self.self)")
                    completionHandler(.cancelAuthenticationChallenge, nil)
                    return
                }
                completionHandler(.useCredential, credential)
                Common_Logs.debug("Authenticated using Basic Auth", "\(Self.self)")
                return
            }

            // -------------------------------------------
            // SSL pinning (server trust)
            // -------------------------------------------
            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }

            // Extract the leaf (server) certificate
            guard
                let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
                let serverPublicKey = SecCertificateCopyKey(serverCertificate),
                let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data?
            else {
                Common_Logs.error("Failed to read server certificate or public key", "\(Self.self)")
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }

            // Helper for cancel
            func fail(reason: String) {
                Common_Logs.error("SSL pinning failed: \(reason)", "\(Self.self)")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }

            // -------------------------------------------
            // 1) Public Key Hash Pinning
            // -------------------------------------------
            if let hashes = serverPublicHashKeys, !hashes.isEmpty {
                func sha256WithASN1(_ keyData: Data) -> String {
                    // Standard ASN.1 header for RSA 2048 bits
                    let rsa2048Asn1Header: [UInt8] = [
                        0x30, 0x82, 0x01, 0x22, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86,
                        0xF7, 0x0D, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0F, 0x00,
                    ]

                    var buffer = Data(rsa2048Asn1Header)
                    buffer.append(keyData)

                    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
                    buffer.withUnsafeBytes {
                        _ = CC_SHA256($0.baseAddress, CC_LONG(buffer.count), &hash)
                    }
                    return Data(hash).base64EncodedString()
                }

                let hash = sha256WithASN1(serverPublicKeyData)

                if hashes.contains(hash) {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    Common_Logs.debug("Authenticated using public key hash pinning", "\(Self.self)")
                    return
                } else {
                    fail(reason: "Public key hash mismatch: \(hash)")
                    return
                }
            }

            // -------------------------------------------
            // 2) Certificate Pinning
            // -------------------------------------------
            if let paths = pathToCertificates, !paths.isEmpty {
                let localCerts: [Data] = paths.compactMap { NSData(contentsOfFile: $0) as Data? }

                // Evaluate trust first
                let trustOK = SecTrustEvaluateWithError(serverTrust, nil)

                // Remote certificate
                let remoteCertData = SecCertificateCopyData(serverCertificate) as Data

                let match = localCerts.contains { $0 == remoteCertData }

                if trustOK, match {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    Common_Logs.debug("Authenticated using local certificate pinning", "\(Self.self)")
                    return
                } else {
                    fail(reason: "Certificate mismatch or trust failure")
                    return
                }
            }

            // -------------------------------------------
            // No pinning defined → reject (secure by default)
            // -------------------------------------------
            Common_Logs.error("No pinning method defined — challenge rejected", "\(Self.self)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
