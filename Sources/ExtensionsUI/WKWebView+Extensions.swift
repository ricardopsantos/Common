//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import WebKit

public struct CookieInfo: Sendable, Hashable {
    public let name: String
    public let value: String
    public let domain: String
    public let path: String
    public let expiresDate: Date?
    public let isSessionOnly: Bool
    public let isSecure: Bool
    public let isHTTPOnly: Bool
    public let sameSitePolicy: HTTPCookieStringPolicy?

    /// Public so consumers can manually wrap cookies if needed.
    public init(_ cookie: HTTPCookie) {
        name = cookie.name
        value = cookie.value
        domain = cookie.domain
        path = cookie.path
        expiresDate = cookie.expiresDate
        isSessionOnly = cookie.expiresDate == nil
        isSecure = cookie.isSecure
        isHTTPOnly = cookie.isHTTPOnly
        sameSitePolicy = cookie.sameSitePolicy
    }

    /// If you still want the old `[String: Any]` shape.
    public var propertiesDict: [String: Any] {
        var props: [String: Any] = [
            HTTPCookiePropertyKey.name.rawValue: name,
            HTTPCookiePropertyKey.value.rawValue: value,
            HTTPCookiePropertyKey.domain.rawValue: domain,
            HTTPCookiePropertyKey.path.rawValue: path,
        ]

        if let expiresDate {
            props[HTTPCookiePropertyKey.expires.rawValue] = expiresDate
        }

        if isSecure {
            props["Secure"] = true
        }

        if isHTTPOnly {
            props["HTTPOnly"] = true
        }

        if let sameSitePolicy {
            props["SameSitePolicy"] = sameSitePolicy.rawValue
        }

        return props
    }
}

public extension WKWebView {
    // MARK: - Get Cookies

    /// Async version that returns typed cookies. Pass `matchingDomain` to filter (substring match).
    static func getCookies(matchingDomain: String? = nil) async -> [CookieInfo] {
        let store = WKWebsiteDataStore.default().httpCookieStore

        let cookies: [HTTPCookie] = await withCheckedContinuation { continuation in
            store.getAllCookies { continuation.resume(returning: $0) }
        }

        let filtered = cookies.filter { cookie in
            guard let matchingDomain else { return true }
            return cookie.domain.range(of: matchingDomain, options: .caseInsensitive) != nil
        }

        return filtered.map(CookieInfo.init)
    }

    /// Backward-compatible completion wrapper that mimics your original signature.
    static func getCookies(
        for domain: String? = nil,
        completion: @escaping @Sendable ([String: Any]) -> Void
    ) {
        Task {
            let cookies = await getCookies(matchingDomain: domain)
            // Preserve previous API shape: [cookieName: properties]
            let dict = Dictionary(uniqueKeysWithValues: cookies.map { ($0.name, $0.propertiesDict) })
            completion(dict)
        }
    }

    // MARK: - Delete Cookies / Data

    /// Deletes ALL cookies (WK + URLSession/HTTPCookieStorage) and website data.
    /// Optionally limit by `since` (defaults to .distantPast).
    static func cleanAllCookies(since _: Date = .distantPast) async {
        // 1) URLSession / legacy cookies
        let httpStorage = HTTPCookieStorage.shared
        httpStorage.cookies?.forEach { httpStorage.deleteCookie($0) }
        // removeCookies(since:) automatically removes old cookies from storage

        // 2) WK cookies
        let wkStore = WKWebsiteDataStore.default().httpCookieStore
        let all = await withCheckedContinuation { continuation in
            wkStore.getAllCookies { continuation.resume(returning: $0) }
        }

        await withTaskGroup(of: Void.self) { group in
            for cookie in all {
                group.addTask { await deleteCookie(cookie, in: wkStore) }
            }
        }

        // 3) Clear all other website data (cache, local storage, indexed DB, etc.)
        let allTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: allTypes) { records in
                WKWebsiteDataStore.default().removeData(ofTypes: allTypes, for: records) {
                    continuation.resume()
                }
            }
        }
    }

    /// Deletes cookies whose domain contains `matchingDomain` (case-insensitive).
    static func deleteCookies(matchingDomain: String) async {
        let wkStore = WKWebsiteDataStore.default().httpCookieStore

        let all = await withCheckedContinuation { continuation in
            wkStore.getAllCookies { continuation.resume(returning: $0) }
        }

        let target = all.filter { cookie in
            cookie.domain.range(of: matchingDomain, options: .caseInsensitive) != nil
        }

        await withTaskGroup(of: Void.self) { group in
            for cookie in target {
                group.addTask { await deleteCookie(cookie, in: wkStore) }
            }
        }
    }

    private static func deleteCookie(_ cookie: HTTPCookie, in store: WKHTTPCookieStore) async {
        await withCheckedContinuation { continuation in
            store.delete(cookie) { continuation.resume() }
        }
    }

    // MARK: - Process Pool Reset

    /// Resets the web view’s underlying networking & cookie context.
    /// Call before loading content to ensure it takes effect.
    func refreshCookies() {
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let dateFrom = Date(timeIntervalSince1970: 0)

        dataStore.removeData(ofTypes: types, modifiedSince: dateFrom) {
            print("All website data cleared.")
        }
    }
}
