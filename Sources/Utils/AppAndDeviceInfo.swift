//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Environment Protocols (Testable)

public protocol AppEnvironmentProtocol {
    var supportsMultipleScenes: Bool { get }
    var supportsAlternateIcons: Bool { get }
    var supportsShakeToEdit: Bool { get }
    var applicationState: UIApplication.State { get }
    var bundleVersion: String? { get }
    var bundleShortVersion: String? { get }
    var bundleIdentifier: String { get }
}

public protocol DeviceEnvironmentProtocol {
    var machineName: String { get }
    var systemVersion: String { get }
    var systemName: String { get }
    var deviceName: String { get }
    var model: String { get }
    var userInterfaceIdiom: UIUserInterfaceIdiom { get }
    var batteryState: UIDevice.BatteryState { get }
    var batteryLevel: Float { get }
    var identifierForVendor: UUID? { get }
    var isBatteryMonitoringEnabled: Bool { get set }
    var isLowPowerModeEnabled: Bool { get }
    var isSimulator: Bool { get }
}

// MARK: - Live Environment Implementations

public struct LiveAppEnvironment: AppEnvironmentProtocol {
    public var supportsMultipleScenes: Bool { UIApplication.shared.supportsMultipleScenes }
    public var supportsAlternateIcons: Bool { UIApplication.shared.supportsAlternateIcons }
    public var supportsShakeToEdit: Bool { UIApplication.shared.applicationSupportsShakeToEdit }
    public var applicationState: UIApplication.State { UIApplication.shared.applicationState }
    public var bundleVersion: String? { Bundle.bundleVersion }
    public var bundleShortVersion: String? { Bundle.bundleShortVersion }
    public var bundleIdentifier: String { Bundle.main.bundleIdentifier ?? "" }
}

public struct LiveDeviceEnvironment: DeviceEnvironmentProtocol {
    public var machineName: String { UIDevice.machineNameInfo }
    public var systemVersion: String { UIDevice.current.systemVersion }
    public var systemName: String { UIDevice.current.systemName }
    public var deviceName: String { UIDevice.current.name }
    public var model: String { UIDevice.current.model }
    public var userInterfaceIdiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    public var batteryState: UIDevice.BatteryState { UIDevice.current.batteryState }
    public var batteryLevel: Float { UIDevice.current.batteryLevel }
    public var identifierForVendor: UUID? { UIDevice.current.identifierForVendor }
    public var isBatteryMonitoringEnabled: Bool {
        get { UIDevice.current.isBatteryMonitoringEnabled }
        set { UIDevice.current.isBatteryMonitoringEnabled = newValue }
    }

    public var isLowPowerModeEnabled: Bool { ProcessInfo.processInfo.isLowPowerModeEnabled }
    public var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }
}

// MARK: - Public Facade (testable)

public extension Common {
    enum AppInfo {
        private static var env: AppEnvironmentProtocol = LiveAppEnvironment()
        static func inject(_ mock: AppEnvironmentProtocol) { env = mock }

        public static var supportsMultipleScene: Bool { env.supportsMultipleScenes }
        public static var supportsAlternateIcons: Bool { env.supportsAlternateIcons }
        public static var supportsShakeToEdit: Bool { env.supportsShakeToEdit }

        public static var version: String {
            if let bv = env.bundleVersion, let bsv = env.bundleShortVersion {
                return "\(bsv) (\(bv))"
            }
            return ""
        }

        public static var bundleIdentifier: String { env.bundleIdentifier }

        public static var onBackground: Bool {
            env.applicationState == .background || env.applicationState == .inactive
        }
    }

    enum DeviceInfo {
        private static var env: DeviceEnvironmentProtocol = LiveDeviceEnvironment()
        static func inject(_ mock: DeviceEnvironmentProtocol) { env = mock }

        public static var machineInfo: String { env.machineName }
        public static var operatingSystemVersionString: String { ProcessInfo().operatingSystemVersionString }
        public static var systemVersion: String { env.systemVersion }
        public static var name: String { env.deviceName }
        public static var systemName: String { env.systemName }
        public static var model: String { env.model }
        public static var iPadDevice: Bool { env.userInterfaceIdiom == .pad }
        public static var iPhoneDevice: Bool { env.userInterfaceIdiom == .phone }

        public static var batteryState: String {
            switch env.batteryState {
            case .charging: "Charging"
            case .full: "Full"
            case .unplugged: "Unplugged"
            default: "Unknown"
            }
        }

        public static func setBatteryMonitoring(to: Bool) -> Bool {
            env.isBatteryMonitoringEnabled = to
            return env.isBatteryMonitoringEnabled
        }

        public static var isBatteryMonitoringEnabled: Bool { env.isBatteryMonitoringEnabled }
        public static var batteryIsInLowPower: Bool { env.isLowPowerModeEnabled }

        public static var batteryLevel: String {
            guard env.isBatteryMonitoringEnabled else { return "Unknown" }
            let level = env.batteryLevel
            if level == -1 { return "Unknown" }
            return "\(level)"
        }

        public static var uuid: String { env.identifierForVendor?.uuidString ?? "" }
        public static var isSimulator: Bool { env.isSimulator }
    }
}

//

// MARK: - Preview

//

#if canImport(SwiftUI) && DEBUG
    fileprivate extension Common_Preview {
        struct AppInfo: View {
            public init() {}
            public var body: some View {
                VStack {
                    Group {
                        Text("App Supports Multiple Scene: \(Common.AppInfo.supportsMultipleScene.description)")
                        Text("App Supports Alternate Icons: \(Common.AppInfo.supportsAlternateIcons.description)")
                        Text("App Supports Shake To Edit: \(Common.AppInfo.supportsShakeToEdit.description)")
                    }
                    Divider()
                    Group {
                        Text("Machine Info: \(Common.DeviceInfo.machineInfo)")
                        Text("Device Name: \(Common.DeviceInfo.name)")
                        Text("System Name: \(Common.DeviceInfo.systemName)")
                        Text("Device Model: \(Common.DeviceInfo.model)")
                        Text("System Version 1: \(Common.DeviceInfo.systemVersion)")
                        Text("System Version 2: \(Common.DeviceInfo.operatingSystemVersionString)")
                        Text("Battery Charging State: \(Common.DeviceInfo.batteryState)")
                        Text("Battery Monitoring Enabled: \(Common.DeviceInfo.isBatteryMonitoringEnabled.description)")
                        Text(
                            "Battery Monitoring Enabled (After change)? \(Common.DeviceInfo.setBatteryMonitoring(to: true).description)"
                        )
                        Text("Battery Charge Level: \(Common.DeviceInfo.batteryLevel)")
                    }
                    Spacer()
                }
            }
        }
    }

    #Preview {
        Common_Preview.AppInfo()
    }
#endif
