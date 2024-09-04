//
//  Created by Ricardo Santos on 13/08/2024.
//

import Foundation

public extension CommonCoreData {
    struct Utils {
        static var logsEnabled = !(Common_Utils.onDebug || Common_Utils.onUITests || Common_Utils.onUITests)
        // static var logNumber = 1
        private init() {}
    }
}
