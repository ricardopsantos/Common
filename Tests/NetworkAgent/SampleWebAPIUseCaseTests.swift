//
//  Created by Ricardo Santos on 12/08/2024.
//

@testable @preconcurrency import Common
import Foundation
import Testing

private let cacheManager = Common.CacheManagerForCodableUserDefaultsRepository.shared

@Suite(.serialized)
struct SampleWebAPIUseCaseTests {
    // MARK: - Config / Helpers

    let cancelBag: CancelBag = .init()
    let sampleWebAPIUseCase: SampleWebAPIUseCase = .init(codableCacheManager: cacheManager)

    actor CounterBox {
        var value = 0
        func increment() {
            value += 1
            print("- Value: \(value)")
        }
    }

    /// Mirrors your previous setUp()
    private func resetState() {
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel()
        cacheManager.syncClearAll()
    }

    // MARK: - Tests

    @Test
    func fetchEmployeesPublisher() async {
        resetState()
        let counterBox = CounterBox()
        sampleWebAPIUseCase.fetchEmployeesPublisher()
            .sinkToReceiveValue { some in
                switch some {
                case .success:
                    Task { await counterBox.increment() }
                case .failure: break
                }
            }
            .store(in: TestsGlobal.cancelBag)
        let ok = await eventuallyAsync { await counterBox.value == 1 }
        #expect(ok, "Expected exactly one success emission")
    }

    @Test
    func fetchEmployeesAsync() async {
        resetState()
        let value = try? await sampleWebAPIUseCase.fetchEmployeesAsync()
        #expect(value != nil, "Expected non-nil result from async fetch")
    }

    @Test
    func fetchEmployeesPublisher_cacheElseLoad() async {
        resetState()
        let counterBox = CounterBox()
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheElseLoad)
            .sink(receiveCompletion: { _ in
                Task { await counterBox.increment() }
            }, receiveValue: { _ in }).store(in: cancelBag)
        let ok = await eventuallyAsync { await counterBox.value == 1 }
        #expect(ok, "Expected exactly one success emission")
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        let value = await counterBox.value
        #expect(value == 1, "Expected exactly 1 success emission after 1 second")
    }

    @Test
    func fetchEmployeesPublisher_ignoringCache() async {
        resetState()
        let counterBox = CounterBox()
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .ignoringCache)
            .sink(receiveCompletion: { _ in
                Task { await counterBox.increment() }
            }, receiveValue: { _ in }).store(in: cancelBag)
        let ok = await eventuallyAsync { await counterBox.value == 1 }
        #expect(ok, "Expected exactly one success emission")
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        let value = await counterBox.value
        #expect(value == 1, "Expected exactly 1 success emission after 1 second")
    }
    
    @Test
    func fetchEmployeesPublisher_cacheAndLoad_WithoutCache() async {
        resetState()
        let counterBox = CounterBox()
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheAndLoad)
            .sink(receiveCompletion: { _ in
                Task { await counterBox.increment() }
            }, receiveValue: { _ in }).store(in: cancelBag)
        let ok = await eventuallyAsync { await counterBox.value == 1 }
        #expect(ok, "Expected exactly one success emission")
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        let value = await counterBox.value
        #expect(value == 1, "Expected exactly 1 success emission after 1 second")
    }
    
    @Test(.disabled("Need to be fixed/updadated"))
    func fetchEmployeesPublisher_cacheAndLoad_WithCache() async {
        resetState()
        let counterBox = CounterBox()
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .ignoringCache)
            .sink(receiveCompletion: { _ in
                Task { await counterBox.increment() }
                sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheAndLoad)
                    .sink(receiveCompletion: { _ in
                        Task { await counterBox.increment() }
                    }, receiveValue: { _ in }).store(in: cancelBag)
            }, receiveValue: { _ in }).store(in: cancelBag)

        let ok = await eventuallyAsync { await counterBox.value == 3 }
        #expect(ok, "Expected exactly one success emission")
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        let value = await counterBox.value
        #expect(value == 3, "Expected exactly 3 success emission after 1 second")
    }

    @Test(.disabled("Need to be fixed/updadated"))
    func sslPiningWithCertificates() async {
        resetState()
        guard true else { #expect(true); return }

        var counter = 0
        sampleWebAPIUseCase.fetchEmployeesAvailabilitySLLCertificate(server: .gitHub)
            .sinkToReceiveValue { some in
                switch some {
                case .success: counter += 1
                case .failure: break
                }
            }
            .store(in: TestsGlobal.cancelBag)

        let ok = await eventually { counter == 1 }
        #expect(ok, "Expected exactly one success emission (SSL pinning certificates)")
    }

    @Test(.disabled("Need to be fixed/updadated"))
    func sslPiningWithPublicHashKeys() async {
        resetState()
        guard true else { #expect(true); return }

        let value = try? await sampleWebAPIUseCase
            .fetchEmployeesAvailabilitySLLHashKeys(server: .gitHub)
            .async()
        #expect(value != nil, "Expected non-nil result (SSL pinning public keys)")
    }

    @Test(.disabled("Need to be fixed/updadated"))
    func authenticationHandlerWithHashKeys() async {
        resetState()
        let server: CommonNetworking.AuthenticationHandler.Server = .googleUkWithHashKeys
        let delegate = CommonNetworking.AuthenticationHandler(server: server)
        let urlSession = URLSession(
            configuration: .defaultForNetworkAgent(),
            delegate: delegate,
            delegateQueue: nil
        )
        let request = URLRequest(url: URL(string: server.url)!)
        do {
            _ = try await urlSession.data(for: request)
            #expect(true)
        } catch {
            #expect(Bool(false), "Network/authentication failed with error: \(error)")
        }
    }

    @Test(.disabled("Need to be fixed/updadated"))
    func authenticationHandlerWithCertPath() async {
        resetState()
        let server: CommonNetworking.AuthenticationHandler.Server = .googleUkWithCertPath
        let delegate = CommonNetworking.AuthenticationHandler(server: server)
        let urlSession = URLSession(
            configuration: .defaultForNetworkAgent(),
            delegate: delegate,
            delegateQueue: nil
        )
        let request = URLRequest(url: URL(string: server.url)!)
        do {
            _ = try await urlSession.data(for: request)
            #expect(true)
        } catch {
            #expect(Bool(false), "Network/authentication failed with error: \(error)")
        }
    }
}
