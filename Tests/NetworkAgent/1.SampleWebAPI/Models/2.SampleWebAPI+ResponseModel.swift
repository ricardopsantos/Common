//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

@testable import Common
import Foundation

extension SampleWebAPI {
    enum ResponseModel {
        struct EmployeeServiceAvailability: Codable, Hashable {
            public let status: String
            public let data: [Employee]
            public let message: String
            public init() {
                status = ""
                data = []
                message = ""
            }
        }

        struct Employee: Codable, Hashable {
            public let id: Int
            public let employeeName: String
            public let employeeSalary, employeeAge: Int
            public let profileImage: String

            public init() {
                id = 0
                employeeName = ""
                employeeAge = 0
                employeeSalary = 0
                profileImage = ""
            }

            enum CodingKeys: String, CodingKey {
                case id
                case employeeName = "employee_name"
                case employeeSalary = "employee_salary"
                case employeeAge = "employee_age"
                case profileImage = "profile_image"
            }
        }
        
        struct HttpBinJSONResponse: Decodable {
            let slideshow: Slideshow?

            struct Slideshow: Decodable {
                let title: String?
                let date: String?
            }
        }

        struct HttpBinPostResponse: Decodable {
            let json: Data

            enum CodingKeys: String, CodingKey {
                case json
            }
        }

        struct Todo: Decodable, Equatable {
            let id: Int
            let userId: Int
            let title: String
            let completed: Bool
        }
    }
}
