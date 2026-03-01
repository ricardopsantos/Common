//
//  CKError+Extensions.swift
//  Common
//
//  Created by Ricardo Santos on 23/09/2024.
//

import CloudKit
import Foundation

// https://www.toptal.com/ios/sync-data-across-devices-with-cloudkit

public extension CKError {
    // MARK: - Convenience flags

    /// True if the record is missing because the zone or item doesn't exist
    var isRecordNotFound: Bool {
        isZoneNotFound || isUnknownItem
    }

    var isZoneNotFound: Bool {
        matches(.zoneNotFound)
    }

    var isUnknownItem: Bool {
        matches(.unknownItem)
    }

    /// Conflict: server has a newer version of the record
    var isConflict: Bool {
        matches(.serverRecordChanged)
    }

    // MARK: - Error Matching

    /// Checks if this CKError or any nested partialFailure CKErrors match the given code.
    func matches(_ code: CKError.Code) -> Bool {
        if self.code == code { return true }

        guard self.code == .partialFailure,
              let nested = partialErrorsByItemID?.values
        else {
            return false
        }

        return nested
            .compactMap { $0 as? CKError }
            .contains { $0.matches(code) }
    }

    // MARK: - Conflict Merge Records

    /// Retrieves `(clientRecord, serverRecord)` if this or any nested error is a `.serverRecordChanged` conflict.
    func getMergeRecords() -> (CKRecord?, CKRecord?) {
        // Direct conflict
        if code == .serverRecordChanged {
            return (clientRecord, serverRecord)
        }

        // PartialFailure: search nested
        guard code == .partialFailure,
              let nested = partialErrorsByItemID?.values
        else {
            return (nil, nil)
        }

        for case let ckError as CKError in nested {
            let merge = ckError.getMergeRecords()
            if merge.0 != nil || merge.1 != nil {
                return merge
            }
        }

        return (nil, nil)
    }
}
