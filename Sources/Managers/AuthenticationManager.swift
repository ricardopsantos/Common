//
//  AuthenticationManager.swift
//  Common
//
//  Created by Ricardo Santos on 22/02/2025.
//

import LocalAuthentication

public extension Common {
    struct AuthenticationManager {
        public static var shared = AuthenticationManager()

        /// Authenticate the user using biometrics or passcode.
        /// - Parameter reason: The reason to display for authentication.
        /// - Returns: A boolean indicating whether authentication was successful.
        /// - Throws: An error if authentication fails or is unavailable.
        public func authenticateUser(reason: String = "Authenticate to continue the operation") async throws -> Bool {
            let context = LAContext()
            var error: NSError?

            // Check if authentication (biometric or passcode) is available
            guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                LogsManager.error("Authentication not available", "\(Self.self)")
                throw error ?? NSError(
                    domain: "com.\(AuthenticationManager.self).BiometricAuth",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Authentication not available"]
                )
            }

            // Perform authentication with biometrics or passcode fallback
            return try await withCheckedThrowingContinuation { continuation in
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                    if success {
                        continuation.resume(returning: true)
                    } else if let authError {
                        LogsManager.error("\(authError)", "\(Self.self)")
                        continuation.resume(throwing: authError)
                    } else {
                        LogsManager.error("Authentication failed for an unknown reason", "\(Self.self)")
                        continuation.resume(throwing: NSError(
                            domain: "com.\(AuthenticationManager.self).BiometricAuth",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Authentication failed for an unknown reason"]
                        ))
                    }
                }
            }
        }
    }
}
