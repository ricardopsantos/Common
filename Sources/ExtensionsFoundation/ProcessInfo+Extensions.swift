//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import CoreData
import Foundation

extension ProcessInfo {
    static var isRunningUnitTests: Bool {
        processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
