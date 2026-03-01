//
//  InterfaceStyleTests.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

@testable @preconcurrency import Common
import Foundation
import Testing

@Suite(.serialized)
struct InterfaceStyleTests {
    @Test
    func testRawValueInit() {
        #expect(Common.InterfaceStyle(rawValue: "light") == .light)
        #expect(Common.InterfaceStyle(rawValue: "LIGHT") == .light)
        #expect(Common.InterfaceStyle(rawValue: "Dark") == .dark)
        #expect(Common.InterfaceStyle(rawValue: "unknown") == nil)
    }

    @Test
    func testIntValue() {
        #expect(Common.InterfaceStyle.light.intValue == 1)
        #expect(Common.InterfaceStyle.dark.intValue == 2)
    }

    @Test
    func testAlternative() {
        #expect(Common.InterfaceStyle.light.alternative == .dark)
        #expect(Common.InterfaceStyle.dark.alternative == .light)
    }

    @Test
    func testMappingFromUIKitStyle() {
        #expect(Common.InterfaceStyle.from(.unspecified) == .light)
        #expect(Common.InterfaceStyle.from(.light) == .light)
        #expect(Common.InterfaceStyle.from(.dark) == .dark)
    }
}
