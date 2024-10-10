//
//  CloudKitManager.swift
//
//  Created by Ricardo Santos on 23/09/2024.
//

import Foundation
import CloudKit

/**

 https://medium.com/@jakir/sync-swiftui-coredata-app-with-icloud-using-cloudkit-9162ae250a22

  https://medium.com/@islammoussa.eg/implementing-seamless-app-version-management-in-ios-with-cloudkit-bf5715b78283

  In CloudKit, a __zone__ is a way to organize and manage your app's data within a database.
  CloudKit provides two types of databases: the public and private databases, and within these, you can create custom zones.

  __1. Default Zone:__
  Each database (public or private) comes with a default zone, where records can be stored if you don’t need complex data organization.
  You can just use this zone for simpler use cases.

  __2. Custom Zones:__
  If you need more control over your data (like organizing data into groups or supporting offline syncing), you can create custom zones.
  This allows you to partition your data within the database.

  Custom zones give you more flexibility for managing data, such as:
  - Batch operations: Perform operations like saving, fetching, or deleting multiple records in one zone as a transaction.
  - Offline Support: CloudKit automatically supports offline data sync for custom zones, helping manage conflicts and merging changes when the device goes back online.
  - Atomic Transactions: You can save multiple records at once, and either all records are saved or none, ensuring data consistency.
  */

open class CloudKitManager {
    public private(set) var container: CKContainer
    public private(set) var publicCloudDatabase: CKDatabase
    public private(set) var privateCloudDatabase: CKDatabase

    /// Can be overridden by subclase to disable logs
    open func loggerEnabled() -> Bool {
        Common_Utils.onDebug
    }

    public init(cloudKit: String) {
        self.container = CKContainer(identifier: cloudKit)
        self.publicCloudDatabase = container.publicCloudDatabase
        self.privateCloudDatabase = container.privateCloudDatabase
    }
}

//
// MARK: - Utils
//

public extension CloudKitManager {
    /// Time: 0.003 s
    func iCloudIsAvailable(completion: @escaping (Bool) -> Void) {
        CKContainer.default().accountStatus { [weak self] accountStatus, error in
            guard let self = self else { return }
            switch accountStatus {
            case .available:
                completion(true)
            case .noAccount:
                if loggerEnabled() {
                    Common_Logs.debug("No iCloud account is signed in.")
                }
                completion(false)
            case .restricted:
                if loggerEnabled() {
                    Common_Logs.debug("iCloud access is restricted.")
                }
                completion(false)
            case .couldNotDetermine:
                if let error = error {
                    Common_Logs.error("Error determining iCloud status: \(error.localizedDescription)")
                }
                completion(false)
            case .temporarilyUnavailable:
                if loggerEnabled() {
                    Common_Logs.debug("iCloud access is temporarily unavailable.")
                }
                completion(false)
            @unknown default:
                if loggerEnabled() {
                    Common_Logs.debug("Unknown iCloud account status.")
                }
                completion(false)
            }
        }
    }

    func createZone(zoneID: CKRecordZone.ID?, completion: @escaping (Bool) -> Void) {
        iCloudIsAvailable { [weak self] available in
            guard available else { return }
            guard let self = self else { return }
            guard let zoneID = zoneID else { return }

            // Check if the zone already exists
            self.privateCloudDatabase.fetch(withRecordZoneID: zoneID) { [weak self] zone, error in
                guard let self = self else { return }

                if zone != nil {
                    // Zone already exists
                    completion(true)
                } else if let ckError = error as? CKError, ckError.code == .zoneNotFound {
                    // Zone doesn't exist, create it
                    let recordZone = CKRecordZone(zoneID: zoneID)
                    let operation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: [])
                    operation.modifyRecordZonesResultBlock = { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success:
                            if loggerEnabled() {
                                Common_Logs.debug("Zone created: \(zoneID)")
                            }
                            completion(true)
                        case .failure(let error):
                            Common_Logs.error("Error creating zone: \(error)")
                            completion(false)
                        }
                    }
                    operation.qualityOfService = .utility
                    self.privateCloudDatabase.add(operation)
                } else {
                    // Handle other errors (e.g., network errors)
                    Common_Logs.error("Error fetching zone: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                }
            }
        }
    }

    func fetchAllRecords(recordType: String, resultsLimit: Int = 1, database: CKDatabase, completion: @escaping (CKRecord?) -> Void) {
        iCloudIsAvailable { available in
            guard available else {
                completion(nil)
                return
            }
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            let operation = CKQueryOperation(query: query)
            operation.resultsLimit = resultsLimit
            var recordFound = false
            let identifier = "fetchAllRecords" + "_" + recordType + "_" + UUID().uuidString
            Common_CronometerManager.startTimerWith(identifier: identifier)
            operation.recordMatchedBlock = { _, result in
                switch result {
                case .success(let record):
                    recordFound = true
                    completion(record)
                case .failure(let error):
                    Common_Logs.error(error)
                    completion(nil)
                }
            }
            operation.queryResultBlock = { [weak self] operationResult in
                guard let self = self else { return }
                switch operationResult {
                case .success:
                    Common_CronometerManager.timeElapsed(identifier, print: loggerEnabled())
                    if !recordFound {
                        // No record found!
                        completion(nil)
                    }
                case .failure(let error):
                    Common_Logs.error(error)
                    completion(nil)
                }
            }
            database.add(operation)
        }
    }

    func updateRecord(record: CKRecord, details: [String: String] = [:], assets: [String: URL] = [:], database: CKDatabase, completion: @escaping (Bool) -> Void) {
        let identifier = "updateRecord" + "_" + record.recordType + "_" + UUID().uuidString
        Common_CronometerManager.startTimerWith(identifier: identifier)
        iCloudIsAvailable { [weak self] available in
            guard let self = self else { completion(false); return }
            guard available else { completion(false); return }
            guard details.count + assets.count > 0 else { completion(false); return }
            record.bindWith(details: details, assets: assets)
            let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            operation.qualityOfService = .background
            operation.modifyRecordsResultBlock = { [weak self] result in
                guard let self = self else { return }
                Common_CronometerManager.timeElapsed(identifier, print: loggerEnabled())
                switch result {
                case .success:
                    if loggerEnabled() {
                        Common_Logs.debug("Record updated: \(record.recordType)")
                    }
                    completion(true)
                case .failure(let error):
                    Common_Logs.debug("Error updating: \(error)")
                    completion(false)
                }
            }
            database.add(operation)
        }
    }

    func insertRecord(
        recordType: String,
        details: [String: String] = [:],
        assets: [String: URL] = [:],
        database: CKDatabase,
        zoneID: CKRecordZone.ID?,
        completion: @escaping (Bool) -> Void
    ) {
        let identifier = "insertRecord" + "_" + recordType + "_" + UUID().uuidString
        iCloudIsAvailable { available in
            guard available else { completion(false); return }
            guard let zoneID = zoneID else { completion(false); return }
            guard details.count + assets.count > 0 else { completion(false); return }
            let record = CKRecord(recordType: recordType, zoneID: zoneID)
            record.bindWith(details: details, assets: assets)
            database.save(record) { [weak self] _, error in
                guard let self = self else { return }
                Common_CronometerManager.timeElapsed(identifier, print: loggerEnabled())
                if let error = error {
                    Common_Logs.debug("Error adding: \(error)")
                    completion(false)
                } else {
                    if loggerEnabled() {
                        Common_Logs.debug("Record added: \(record.recordType)")
                    }
                    completion(true)
                }
            }
        }
    }
}

public extension CKRecord {
    func bindWith(details: [String: String] = [:], assets: [String: URL] = [:]) {
        details.keys.forEach { key in
            self[key] = details[key]
        }
        assets.keys.forEach { key in
            if let fileURL = assets[key] {
                self[key] = CKAsset(fileURL: fileURL)
            }
        }
    }
}
