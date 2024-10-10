//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation

public extension Common {
    struct PropertyWrappers {
        private init() {}
    }
}

public typealias PWPartialState = Common_PropertyWrappers.PartialState
public typealias PWThreadSafe = Common_PropertyWrappers.ThreadSafeUnfairLock
public typealias PWUserDefaults = Common_PropertyWrappers.UserDefaults
public typealias PWKeychainStorageV1 = Common_PropertyWrappers.KeychainStorageV1
public typealias PWKeychainStorageV2 = Common_PropertyWrappers.KeychainStorageV2
public typealias PWProjectedOnChange = Common_PropertyWrappers.ProjectedOnChange
public typealias PWProjectedOnChangeWithCodingKey = Common_PropertyWrappers.ProjectedOnChangeWithCodingKey

public typealias PWInject = Common_PropertyWrappers.InjectTreadSafe
public typealias PWInjectContainer = Common_PropertyWrappers.InjectContainer
