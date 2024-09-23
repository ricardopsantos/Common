//
//  CKError+Extensions.swift
//  Common
//
//  Created by Ricardo Santos on 23/09/2024.
//

import Foundation
import CloudKit

// https://www.toptal.com/ios/sync-data-across-devices-with-cloudkit

public extension CKError {
    var isRecordNotFound: Bool {
        isZoneNotFound || isUnknownItem
    }

    var isZoneNotFound: Bool {
        isSpecificErrorCode(code: .zoneNotFound)
    }

    var isUnknownItem: Bool {
        isSpecificErrorCode(code: .unknownItem)
    }

    var isConflict: Bool {
        isSpecificErrorCode(code: .serverRecordChanged)
    }

    func isSpecificErrorCode(code: CKError.Code) -> Bool {
        var match = false
        if self.code == code {
            match = true
        } else if self.code == .partialFailure {
            // This is a multiple-issue error. Check the underlying array
            // of errors to see if it contains a match for the error in question.
            guard let errors = partialErrorsByItemID else {
                return false
            }
            for (_, error) in errors {
                if let cke = error as? CKError {
                    if cke.code == code {
                        match = true
                        break
                    }
                }
            }
        }
        return match
    }

    // ServerRecordChanged errors contain the CKRecord information
    // for the change that failed, allowing the client to decide
    // upon the best course of action in performing a merge.
    func getMergeRecords() -> (CKRecord?, CKRecord?) {
        if code == .serverRecordChanged {
            // This is the direct case of a simple serverRecordChanged Error.
            return (clientRecord, serverRecord)
        }
        guard code == .partialFailure else {
            return (nil, nil)
        }
        guard let errors = partialErrorsByItemID else {
            return (nil, nil)
        }
        for (_, error) in errors {
            if let cke = error as? CKError {
                if cke.code == .serverRecordChanged {
                    // This is the case of a serverRecordChanged Error
                    // contained within a multi-error PartialFailure Error.
                    return cke.getMergeRecords()
                }
            }
        }
        return (nil, nil)
    }
}
