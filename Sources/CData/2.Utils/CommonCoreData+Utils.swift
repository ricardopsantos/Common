//
//  Created by Ricardo Santos on 13/08/2024.
//

import Combine
import Foundation

public extension CommonCoreData {
    struct Utils {
        private init() {}
        //

        // MARK: - Logs

        //
        static var logsEnabled = Common_Utils.onDebug

        //

        // MARK: - Events

        //
        public enum OutputEvent: Hashable, Sendable {
            case databaseDidInsertRecord(_ class: String, id: String?) // Inserted record
            case databaseDidUpdateRecord(_ class: String, id: String?) // Updated record
            case databaseDidDeleteRecord(_ class: String, id: String?) // Delete record
        }

        static var output = PassthroughSubject<CommonCoreData.Utils.OutputEvent, Never>()
        public static func outputListener(_ filter: [CommonCoreData.Utils.OutputEvent] = [])
            -> AnyPublisher<CommonCoreData.Utils.OutputEvent, Never>
        {
            if filter.isEmpty {
                output.eraseToAnyPublisher()
            } else {
                output.filter { filter.contains($0) }.eraseToAnyPublisher()
            }
        }
    }
}
