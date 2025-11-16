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
struct NetworkAgentProtocolTests {
    
    let cancelBag: CancelBag = .init()
    let sampleWebAPI: SampleWebAPI = .init()
    var client: CommonNetworking.NetworkAgentClient {
        sampleWebAPI.client
    }
    
    @Test
    func clientRequestPublisher() async {
         var model: SampleWebAPI.ResponseModel.HttpBinJSONResponse?
         var finished: Bool = false
         client.requestPublisher(
            request: SampleWebAPI.Methods.httpbin.urlRequest!,
             decoder: .defaultForWebAPI,
             logger: .none,
             responseFormat: .json
         )
         .sink(
             receiveCompletion: { completion in
                 finished = true
             },
             receiveValue: { value in
                 model = value.model
             }
         )
         .store(in: cancelBag)

         let ok = await eventually { finished }
         #expect(ok)
         #expect(model != nil)
     }
     
    @Test
    func sampleWebAPIRequestPublisher() async {
        var model: SampleWebAPI.ResponseModel.HttpBinJSONResponse?
        var finished: Bool = false
        sampleWebAPI.performRequest(.httpbin)
        .sink(
            receiveCompletion: { completion in
                finished = true
            },
            receiveValue: { value in
                model = value
            }
        )
        .store(in: cancelBag)

        let ok = await eventually { finished }
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
                                               onCompleted: { })
        let ok = await eventually { model != nil }
        #expect(ok)
        #expect(model != nil)
    }
    
    // MARK: - 2) 404 Not Found

    @Test
     func test_404() async {

         var apiError: CommonNetworking.APIError?
         var finished = false

         do {
             let _: SampleWebAPI.ResponseModel.HttpBinJSONResponse = try await sampleWebAPI.performRequest(SampleWebAPI.Methods.httpBinWith(status: 404)).async()
         } catch {
             if let error = error as? CommonNetworking.APIError {
                 apiError = error
             }
             finished = true
         }
         let ok = await eventually { finished }
         #expect(ok)
         #expect(apiError?.isNotFoundHTTPStatusCode ?? false)
     }

}
