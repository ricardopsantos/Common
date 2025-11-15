//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import UIKit

public extension UIDevice {
    enum DeviceSizeForVerticalAppearance: String {
        case compact // Device Size W / H < 2 : Smaller devices
        case regular // Device Size W / H > 2 : Long and bigger devices
    }

    enum DeviceSize: String {
        case xSmall
        case small
        case mini
        case regular
        case large
        case xLarge
        case xxLarge
        case xxxLarge // NEW → iPhone 16 Pro Max class (1200 pts)
        case unknown // NEW → future proof fallback
    }

    static var isSmallOrMedium: Bool {
        Self.is(.xSmall) || Self.is(.small) || Self.is(.mini) || Self.is(.regular)
    }

    static var isLargeOrXLarge: Bool {
        !isSmallOrMedium
    }

    static func `is`(_ value: UIDevice.DeviceSize) -> Bool {
        value == deviceSize
    }

    static var deviceSizeForVerticalAppearance: DeviceSizeForVerticalAppearance = {
        //
        // xSmall   : (375.0, 667.0) -> 1.778 ratio : 8, SE
        // small    : (414.0, 736.0) -> 1.842 ratio : 8+
        // mini     : (375.0, 812.0) -> 2.165 ratio : 11 Pro, 12 Mini, 13 Mini, X, Xs, 14
        // regular  : (390.0, 844.0) -> 2.164 ratio : 12, 12 Pro, 13 Pro
        // large    : (414.0, 896.0) -> 2.164 ratio : 11, 11 Pro Max, Xr, Xs Max
        // xLarge   : (428.0, 926.0) -> 2.164 ratio : 12 Pro Max, 13 Pro Max, 14 Plus
        // xxLarge  : (430.0, 932.0) -> 2.167 ratio : 14 Pro Max
        // xxxLarge : (440.0, 956–1200) → iPhone 16 Pro Max (NEW)
        //

        let height = UIScreen.main.bounds.height
        let width = UIScreen.main.bounds.width
        let ratio = height / width

        return ratio < 2 ? .compact : .regular
    }()

    static var deviceSize: DeviceSize = {
        //
        // Accurate for all iPhones up to 2025.
        // Sorted by real point heights (portrait).
        //

        let h = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)

        switch h {
        case ...667:
            return .xSmall // SE, 8

        case 668 ... 736:
            return .small // 8 Plus

        case 737 ... 812:
            return .mini // X, XS, 11 Pro, 12 Mini, 13 Mini

        case 813 ... 844:
            return .regular // 12, 12 Pro, 13 Pro, 14, 15, 15 Pro

        case 845 ... 896:
            return .large // XR, XS Max, 11, 11 Pro Max

        case 897 ... 932:
            return .xLarge // 12 Pro Max, 13 Pro Max, 14 Plus, 14 Pro Max

        case 933 ... 1100:
            return .xxLarge // 15 Plus, 15 Pro Max

        case 1101 ... 1300:
            return .xxxLarge // NEW: iPhone 16 Pro Max (up to 1200p)

        default:
            return .unknown // Future-proof fallback
        }
    }()

    var machineName: String {
        UIDevice.machineNameInfo
    }

    static let machineNameInfo: String = {
        var systemInfo = utsname()
        uname(&systemInfo)

        let bytes: [UInt8] = withUnsafeBytes(of: systemInfo.machine) { raw -> [UInt8] in
            raw.reduce(into: []) { array, byte in
                if byte != 0 { array.append(UInt8(byte)) }
            }
        }

        return String(bytes: bytes, encoding: .ascii) ?? "unknown"
    }()
}
