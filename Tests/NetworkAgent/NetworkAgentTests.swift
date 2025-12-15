//
//  NetworkAgentProtocolTests.swift
//  Common
//
//  Created by Ricardo Santos on 16/11/2025.
//

import Combine
@testable import Common
import Foundation
import Testing

@Suite(.serialized)
struct NetworkAgentTests {

    actor Flag {
        var finished = false
        func setFinished() { finished = true }
    }
    
    let cancelBag: CancelBag = .init()
    let sampleWebAPI: SampleWebAPI = .init()
    var networkAgent: CommonNetworking.NetworkAgent {
        sampleWebAPI.client
    }

    @Test
    func clientRequestPublisher() async {
        var model: SampleWebAPI.ResponseModel.HttpBinJSONResponse?
        let flag = Flag()
        networkAgent.requestPublisher(
            request: SampleWebAPI.Methods.httpbin.urlRequest!,
            decoder: .defaultForWebAPI,
            logger: .none,
            responseFormat: .json
        )
        .sink(
            receiveCompletion: { _ in
                Task {
                    await flag.setFinished()
                }
            },
            receiveValue: { value in
                model = value.model
            }
        )
        .store(in: cancelBag)

        let ok = await eventuallyAsync {
            await flag.finished
        }
        #expect(ok)
        #expect(model != nil)
    }

    @Test
    func sampleWebAPIRequestPublisher() async {
        var model: SampleWebAPI.ResponseModel.HttpBinJSONResponse?
        let flag = Flag()
        sampleWebAPI.performRequest(.httpbin)
            .sink(
                receiveCompletion: { _ in
                    Task {
                        await flag.setFinished()
                    }
                },
                receiveValue: { value in
                    model = value
                }
            )
            .store(in: cancelBag)

        let ok = await eventuallyAsync {
            await flag.finished
        }
        #expect(ok)
        #expect(ok)
        #expect(model != nil)
    }

    @Test
    func sampleWebAPIRequestAsync1() async {
        var model: SampleWebAPI.ResponseModel.HttpBinJSONResponse?
        model = try? await sampleWebAPI.performRequest(SampleWebAPI.Methods.httpbin).async()
        let ok = await eventually { model != nil }
        #expect(ok)
        #expect(model != nil)
    }

    @Test
    func sampleWebAPIRequestAsync2() async {
        var model: SampleWebAPI.ResponseModel.HttpBinJSONResponse?
        model = try? await sampleWebAPI.requestAsync(request: SampleWebAPI.Methods.httpbin.urlRequest!,
                                                     decoder: .defaultForWebAPI,
                                                     logger: .allOff,
                                                     responseType: .json,
                                                     onCompleted: {})
        let ok = await eventually { model != nil }
        #expect(ok)
        #expect(model != nil)
    }

    // MARK: - 2) 404 Not Found

    @Test
    func test_404() async {
        var apiError: CommonNetworking.APIError?
        let flag = Flag()
        do {
            let _: SampleWebAPI.ResponseModel.HttpBinJSONResponse = try await sampleWebAPI
                .performRequest(SampleWebAPI.Methods.httpBinWith(status: 404)).async()
        } catch {
            if let error = error as? CommonNetworking.APIError {
                apiError = error
            }
            await flag.setFinished()
        }
        let ok = await eventuallyAsync {
            await flag.finished
        }
        #expect(ok)
        #expect(apiError?.isNotFoundHTTPStatusCode ?? false)
    }
}
