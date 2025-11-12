//
//  Created by Ricardo Santos on 12/08/2024.
//

import Foundation
import Testing
@testable @preconcurrency import Common

@Suite(.serialized)
struct SampleWebAPITests {

    // MARK: - Config / Helpers

    private let maxTimeoutSeconds = Double(TestsGlobal.timeout)

    private var sampleWebAPIUseCase: SampleWebAPIUseCase { SampleWebAPIUseCase() }

    /// Mirrors your previous setUp()
    private func resetState() {
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel()
    }

    // MARK: - Tests

    @Test
    func fetchEmployeesAvailabilityCustom() async {
        resetState()
        guard true /* enabled() */ else { #expect(true); return }

        var counter = 0
        sampleWebAPIUseCase.fetchEmployeesAvailabilityCustom()
            .sinkToReceiveValue { some in
                switch some {
                case .success: counter += 1
                case .failure: break
                }
            }
            .store(in: TestsGlobal.cancelBag)

        let ok = await eventually(timeoutSeconds: maxTimeoutSeconds) { counter == 1 }
        #expect(ok, "Expected exactly one success emission")
    }

    @Test
    func fetchEmployeesAvailabilityGenericPublisher() async {
        resetState()
        guard true else { #expect(true); return }

        var counter = 0
        sampleWebAPIUseCase.fetchEmployeesPublisher()
            .sinkToReceiveValue { some in
                switch some {
                case .success: counter += 1
                case .failure: break
                }
            }
            .store(in: TestsGlobal.cancelBag)

        let ok = await eventually(timeoutSeconds: maxTimeoutSeconds) { counter == 1 }
        #expect(ok, "Expected exactly one success emission")
    }

    @Test
    func fetchEmployeesAvailabilityGenericAsync() async {
        resetState()
        guard true else { #expect(true); return }

        let value = try? await sampleWebAPIUseCase.fetchEmployeesAsync()
        #expect(value != nil, "Expected non-nil result from async fetch")
    }

    @Test
    func fetchEmployeesAvailabilityCustomWithCache() async {
        resetState()
        guard true else { #expect(true); return }

        var counter = 0
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheElseLoad)
            .sinkToReceiveValue { some in
                switch some {
                case .success: counter += 1
                case .failure: break
                }
            }
            .store(in: TestsGlobal.cancelBag)

        let ok = await eventually(timeoutSeconds: maxTimeoutSeconds) { counter == 1 }
        #expect(ok, "Expected exactly one success emission (cacheElseLoad)")
    }

    @Test
    func fetchEmployeesAvailabilityGenericPublisherWithCache() async {
        resetState()
        guard true else { #expect(true); return }

        var counter = 0
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheElseLoad)
            .sinkToReceiveValue { some in
                switch some {
                case .success: counter += 1
                case .failure: break
                }
            }
            .store(in: TestsGlobal.cancelBag)

        let ok = await eventually(timeoutSeconds: maxTimeoutSeconds) { counter == 1 }
        #expect(ok, "Expected exactly one success emission (cacheElseLoad)")
    }

    @Test
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

        let ok = await eventually(timeoutSeconds: maxTimeoutSeconds) { counter == 1 }
        #expect(ok, "Expected exactly one success emission (SSL pinning certificates)")
    }

    @Test
    func sslPiningWithPublicHashKeys() async {
        resetState()
        guard true else { #expect(true); return }

        let value = try? await sampleWebAPIUseCase
            .fetchEmployeesAvailabilitySLLHashKeys(server: .gitHub)
            .async()
        #expect(value != nil, "Expected non-nil result (SSL pinning public keys)")
    }

    @Test
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

    @Test
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
