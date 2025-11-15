//
//  MockNWPath.swift
//  Works without subclassing or constructing NWPath
//

@testable import Common
import Foundation
import Network
import ObjectiveC.runtime
import Testing

// -----------------------------------------------------------------------------

// MARK: - PRIVATE: Create NWPath using private initializer

// -----------------------------------------------------------------------------
//
// This uses a private initializer exposed to Objective-C runtime.
// Works only inside test bundles.
// -----------------------------------------------------------------------------

private func makeFakeNWPath(status: NWPath.Status) -> NWPath {
    typealias InitSig = @convention(c) (AnyObject, Selector, Int, Bool, Bool, Bool, Bool) -> AnyObject

    let cls: AnyClass = NWPath.self
    let selector = NSSelectorFromString("initWithStatus:isExpensive:supportsDNS:supportsIPv4:supportsIPv6:")
    let ctor = class_getInstanceMethod(cls, selector)!
    let imp = method_getImplementation(ctor)

    let fn = unsafeBitCast(imp, to: InitSig.self)
    return fn(
        cls.alloc(),
        selector,
        status.rawValue,
        false,
        true,
        true,
        true
    ) as! NWPath
}

// -----------------------------------------------------------------------------

// MARK: - SWIZZLING: Intercept NWPathMonitor callback

// -----------------------------------------------------------------------------
//
// We swizzle _pathUpdateHandler_ so we can replace the NWPath parameter.
// -----------------------------------------------------------------------------

private var mockStatusKey: UInt8 = 0

extension NWPathMonitor {
    /// Set the fake status to inject
    func injectFake(status: NWPath.Status) {
        objc_setAssociatedObject(self, &mockStatusKey, status.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Read fake status
    private var injectedStatus: NWPath.Status? {
        if let raw = objc_getAssociatedObject(self, &mockStatusKey) as? Int,
           let s = NWPath.Status(rawValue: raw)
        {
            return s
        }
        return nil
    }

    /// Swizzle once
    static func swizzleForTests() {
        enum Once { static var done = false }
        guard !Once.done else { return }
        Once.done = true

        let cls: AnyClass = NWPathMonitor.self

        let originalSel = NSSelectorFromString("handlePathUpdate:")
        let swizzledSel = #selector(NWPathMonitor.swizzled_handlePathUpdate(_:))

        let original = class_getInstanceMethod(cls, originalSel)!
        let swizzled = class_getInstanceMethod(cls, swizzledSel)!

        method_exchangeImplementations(original, swizzled)
    }

    @objc private func swizzled_handlePathUpdate(_ path: NWPath) {
        if let fake = injectedStatus {
            let fakePath = makeFakeNWPath(status: fake)
            swizzled_handlePathUpdate(fakePath) // call original
        } else {
            swizzled_handlePathUpdate(path) // normal call
        }
    }
}

// -----------------------------------------------------------------------------

// MARK: - Tests

// -----------------------------------------------------------------------------

@Suite("NetworkMonitor Tests")
struct NetworkMonitorTests {
    init() {
        NWPathMonitor.swizzleForTests()
    }

    @Test("Initial satisfied → .internetConnectionAvailable")
    func test_initial_available() async {
        let monitor = CommonNetworking.NetworkMonitor.shared
        let clock = ManualClock()
        var out: CommonNetworking.NetworkStatus?

        monitor.start { v in
            out = v
            clock.resume()
        }

        monitor.injectFake(status: .satisfied)

        await clock.sleep(until: .now + .milliseconds(50))
        #expect(out == .internetConnectionAvailable)
    }

    @Test("Initial unsatisfied → .internetConnectionLost")
    func test_initial_lost() async {
        let monitor = CommonNetworking.NetworkMonitor.shared
        let clock = ManualClock()
        var out: CommonNetworking.NetworkStatus?

        monitor.start { v in
            out = v
            clock.resume()
        }

        monitor.injectFake(status: .unsatisfied)

        await clock.sleep(until: .now + .milliseconds(50))
        #expect(out == .internetConnectionLost)
    }

    @Test("lost → satisfied → .internetConnectionRecovered")
    func test_recovered() async {
        let monitor = CommonNetworking.NetworkMonitor.shared
        let clock = ManualClock()
        var events: [CommonNetworking.NetworkStatus] = []

        monitor.start { v in
            events.append(v)
            if events.count == 2 { clock.resume() }
        }

        monitor.injectFake(status: .unsatisfied)
        monitor.injectFake(status: .satisfied)

        await clock.sleep(until: .now + .milliseconds(80))
        #expect(events == [.internetConnectionLost, .internetConnectionRecovered])
    }
}

@Suite("NetworkMonitorViewModel")
struct NetworkMonitorViewModelTests {
    init() {
        NWPathMonitor.swizzleForTests()
    }

    @Test("ViewModel reacts to status")
    func test_viewmodel_updates() async {
        let vm = CommonNetworking.NetworkMonitorViewModel.shared
        let monitor = CommonNetworking.NetworkMonitor.shared

        let clock = ManualClock()
        var result: CommonNetworking.NetworkStatus?

        let cancellable = vm.$networkStatus.dropFirst().sink { value in
            result = value
            clock.resume()
        }

        monitor.injectFake(status: .unsatisfied)

        await clock.sleep(until: .now + .milliseconds(80))

        cancellable.cancel()
        #expect(result == .internetConnectionLost)
    }
}
