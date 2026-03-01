//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import CoreData
import Foundation

public protocol SyncCoreDataManagerSaveProtocol {
    var viewContext: NSManagedObjectContext { get }
    func saveContext()
}

public extension SyncCoreDataManagerSaveProtocol {
    func saveContext() {
        CommonCoreData.Utils.syncSave(viewContext: viewContext)
    }
}
