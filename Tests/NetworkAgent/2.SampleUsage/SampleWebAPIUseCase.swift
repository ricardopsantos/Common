//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Combine
@testable import Common
import Foundation

class SampleWebAPIUseCase {
    let webAPI: SampleWebAPI = .init(session: .defaultForNetworkAgent)
    let codableCacheManager: CodableCacheManagerProtocol?
    public init(codableCacheManager: CodableCacheManagerProtocol?) {
        self.codableCacheManager = codableCacheManager
    }

    //

    // MARK: - Simple API Requests

    //
    func fetchEmployeesPublisher() -> AnyPublisher<
        SampleWebAPI.ResponseModel.EmployeeServiceAvailability,
        CommonNetworking.APIError
    > {
        let requestDto = SampleWebAPI.RequestModel.Employee(id: "id")
        return webAPI.performRequest(SampleWebAPI.Methods.fetchEmployees(requestDto))
    }

    func fetchEmployeesAsync() async throws -> SampleWebAPI.ResponseModel.EmployeeServiceAvailability {
        let requestDto = SampleWebAPI.RequestModel.Employee(id: "id")
        return try await webAPI.performRequest(SampleWebAPI.Methods.fetchEmployees(requestDto)).async()
    }

    //

    // MARK: - API Request + Cache

    //
    func fetchEmployees(cachePolicy: Common.CachePolicy) -> AnyPublisher<
        SampleWebAPI.ResponseModel.EmployeeServiceAvailability,
        CommonNetworking.APIError
    > {
        let serviceKey = #function
        let requestDto = SampleWebAPI.RequestModel.Employee(id: "id")
        let apiRequest: AnyPublisher<
            SampleWebAPI.ResponseModel.EmployeeServiceAvailability,
            CommonNetworking.APIError
        > = webAPI.performRequest(SampleWebAPI.Methods.fetchEmployees(requestDto))
        let serviceParams: [any Hashable] = [requestDto.id]
        let apiResponseType = SampleWebAPI.ResponseModel.EmployeeServiceAvailability.self
        return Common.GenericRequestWithCodableCache.perform(
            apiRequest,
            apiResponseType,
            cachePolicy,
            serviceKey,
            serviceParams,
            60 * 24 * 30, // 1 month
            codableCacheManager
        ).eraseToAnyPublisher()
    }

    //

    // MARK: - API Request + SSL Pinning (with Certificate)

    //
    func fetchEmployeesAvailabilitySLLCertificate(server: CommonNetworking.AuthenticationHandler
        .Server) -> AnyPublisher<
        SampleWebAPI.ResponseModel.EmployeeServiceAvailability,
        CommonNetworking.APIError
    > {
        let webAPISSLPinningWithCertificates = SampleWebAPI(
            session: .defaultForNetworkAgent,
            pathToCertificates: server.pathToCertificates ?? []
        )
        let requestDto = SampleWebAPI.RequestModel.Employee(id: "id")
        return webAPISSLPinningWithCertificates.performRequest(SampleWebAPI.Methods.fetchEmployees(requestDto))
    }

    //

    // MARK: - API Request + SSL Pinning (with Certificate)

    //
    func fetchEmployeesAvailabilitySLLHashKeys(server: CommonNetworking.AuthenticationHandler
        .Server) -> AnyPublisher<
        SampleWebAPI.ResponseModel.EmployeeServiceAvailability,
        CommonNetworking.APIError
    > {
        let webAPISSLPinningWithCertificates = SampleWebAPI(
            session: .defaultForNetworkAgent,
            pathToCertificates: server.publicHashKeys
        )
        let requestDto = SampleWebAPI.RequestModel.Employee(id: "id")
        return webAPISSLPinningWithCertificates.performRequest(SampleWebAPI.Methods.fetchEmployees(requestDto))
    }
}
