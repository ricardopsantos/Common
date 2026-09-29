//
//  Created by Ricardo Santos on 12/08/2024.
//

import Combine
import Foundation
import Testing
//
@testable import Common
/// Serialised: shares `TestsGlobal.cancelBag` and hits a live endpoint.
@Suite(.serialized)
struct SampleWebAPI_Tests {
    func enabled() -> Bool {
        true
    }

    init() {
        TestsGlobal.loadedAny = nil
        TestsGlobal.cancelBag.cancel()
    }

    private var sampleWebAPIUseCase: SampleWebAPIUseCaseLegacy {
        SampleWebAPIUseCaseLegacy()
    }

    @Test
    func test_fetchEmployeesAvailabilityCustom() async {
        guard enabled() else { return }
        var counter = 0
        sampleWebAPIUseCase.fetchEmployeesAvailabilityCustom()
            .sinkToReceiveValue { some in
                switch some {
                case .success:
                    counter += 1
                case .failure: ()
                }
            }.store(in: TestsGlobal.cancelBag)
        #expect(await eventually { counter == 1 })
    }

    @Test
    func test_fetchEmployeesAvailabilityGenericPublisher() async {
        guard enabled() else { return }
        var counter = 0
        sampleWebAPIUseCase.fetchEmployeesPublisher()
            .sinkToReceiveValue { some in
                switch some {
                case .success:
                    counter += 1
                case .failure: ()
                }
            }.store(in: TestsGlobal.cancelBag)
        #expect(await eventually { counter == 1 })
    }

    @Test
    func test_fetchEmployeesAvailabilityGenericAsync() async {
        guard enabled() else { return }
        let value = try? await sampleWebAPIUseCase.fetchEmployeesAsync()
        #expect(await eventually { value != nil })
    }

    @Test
    func test_fetchEmployeesAvailabilityCustomWithCache() async {
        guard enabled() else { return }
        var counter = 0
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheElseLoad)
            .sinkToReceiveValue { some in
                switch some {
                case .success:
                    counter += 1
                case .failure: ()
                }
            }.store(in: TestsGlobal.cancelBag)
        #expect(await eventually { counter == 1 })
    }

    @Test
    func test_fetchEmployeesAvailabilityGenericPublisherWithCache() async {
        guard enabled() else { return }
        var counter = 0
        sampleWebAPIUseCase.fetchEmployees(cachePolicy: .cacheElseLoad)
            .sinkToReceiveValue { some in
                switch some {
                case .success:
                    counter += 1
                case .failure: ()
                }
            }.store(in: TestsGlobal.cancelBag)
        #expect(await eventually { counter == 1 })
    }

    @Test
    func test_sslPiningWithCertificates() async {
        guard enabled() else { return }
        var counter = 0
        sampleWebAPIUseCase.fetchEmployeesAvailabilitySLLCertificate(server: .gitHub)
            .sinkToReceiveValue { some in
                switch some {
                case .success:
                    counter += 1
                case .failure: ()
                }
            }.store(in: TestsGlobal.cancelBag)
        #expect(await eventually { counter == 1 })
    }

    @Test
    func test_sslPiningWithPublicHashKeys() async {
        guard enabled() else { return }
        let value = try? await sampleWebAPIUseCase.fetchEmployeesAvailabilitySLLHashKeys(server: .gitHub).async()
        #expect(await eventually { value != nil })
    }

    @Test
    func test_authenticationHandlerWithHashKeys() async {
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
        } catch {
            Issue.record("unexpected path")
        }
    }

    @Test
    func test_authenticationHandlerWithCertPath() async {
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
        } catch {
            Issue.record("unexpected path")
        }
    }
}
