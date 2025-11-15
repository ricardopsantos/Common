//
//  AppInfoTests.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

@testable @preconcurrency import Common
import Foundation
import Testing
import UIKit

struct MockAppEnvironment: AppEnvironmentProtocol {
    var supportsMultipleScenes = false
    var supportsAlternateIcons = false
    var supportsShakeToEdit = false
    var applicationState: UIApplication.State = .active
    var bundleVersion: String? = "42"
    var bundleShortVersion: String? = "1.2.3"
    var bundleIdentifier: String = "com.example.app"
}

struct MockDeviceEnvironment: DeviceEnvironmentProtocol {
    var machineName = "MockMachine"
    var systemVersion = "17.0"
    var systemName = "iOS"
    var deviceName = "Mock iPhone"
    var model = "iPhone 99"
    var userInterfaceIdiom: UIUserInterfaceIdiom = .phone
    var batteryState: UIDevice.BatteryState = .charging
    var batteryLevel: Float = 0.9
    var identifierForVendor: UUID? = UUID(uuidString: "11111111-2222-3333-4444-555555555555")
    var isBatteryMonitoringEnabled = true
    var isLowPowerModeEnabled = false
    var isSimulator = false
}

@Suite(.serialized)
struct AppInfoTests {
    @Test
    func testVersion() {
        Common.AppInfo.inject(MockAppEnvironment())
        #expect(Common.AppInfo.version == "1.2.3 (42)")
    }

    @Test
    func testBundleIdentifier() {
        Common.AppInfo.inject(MockAppEnvironment())
        #expect(Common.AppInfo.bundleIdentifier == "com.example.app")
    }

    @Test
    func testOnBackground() {
        var mock = MockAppEnvironment()
        mock.applicationState = .background
        Common.AppInfo.inject(mock)

        #expect(Common.AppInfo.onBackground == true)
    }
}
