//
//  Actors.swift
//  Common
//
//  Created by Ricardo Santos on 23/09/2024.
//

import Foundation

/**

 https://blog.stackademic.com/goodbye-singletons-embracing-actors-in-swift-6-5c520fe0f15c
 https://medium.com/@bitsandbytesch/actors-and-concurrency-in-swift-a-detailed-exploration-581d2293e47e

 __Actors are a new reference type that protects its mutable state by ensuring that only one task can access that state at a time__.

 ----

  __Actors vs Classes__
 • Classes: Allow concurrent access to their properties and methods, which can lead to data races unless you manually synchronize access (e.g., using locks).
 • Actors: Automatically serialize access to their state, preventing data races by design.

 ----

 */

extension CommonLearnings {
    struct Actors {}
}

//
// MARK: - Basic Usage
//
extension CommonLearnings.Actors {
    actor Counter {
        private var value = 0

        func increment() {
            value += 1
        }

        func getValue() -> Int {
            value
        }

        /// You can create a new asynchronous task using Task {}. This allows you to perform asynchronous work in parallel with other tasks.
        func usage() {
            let counter = Counter()

            Task {
                await counter.increment()
            }

            Task {
                /* let currentValue = */ await counter.getValue()
            }
        }
    }
}

//
// MARK: - Global Actors
//
extension CommonLearnings.Actors {
    /**
     __Global Actors__

     Sometimes, you need a shared actor that can be used across different parts of your app: __global actors__. A global actor is a singleton actor that provides a single
     point of serialization for a particular part of your code.

     For example, the __@MainActor__ global actor ensures that certain operations are always performed on the main thread, which is crucial for updating the UI:

     */

    @MainActor
    func updateUI() {
        // Code that updates the UI
    }

    /// In addition to the built-in @MainActor, you can create custom global actors to control the execution context of certain parts of your app.
    @globalActor
    enum MyGlobalActor {
        /// In this example, __MyGlobalActor__ is a custom global actor. It encapsulates its own actor type (__ActorType__),
        /// which is used to provide the shared instance for concurrency management.
        actor ActorType {}
        static let shared = ActorType()
    }

    class GlobalActorUsage {
        @MyGlobalActor var sharedResource: [String] = []

        @MyGlobalActor
        func updateResource(with value: String) {
            sharedResource.append(value)
        }
    }
}

//
// MARK: - Actors instead of Singletons
//

extension CommonLearnings.Actors {
    /// Use @MainActor for UI-related Work
    @MainActor
    final class UIManager {
        static let shared = UIManager()
        var theme: String = "Dark"
    }

    /// Global Actors for Background Tasks
    @globalActor
    actor BackgroundActor {
        static let shared = BackgroundActor()
    }

    @BackgroundActor
    final class DataHandler {
        var data: [String] = []
    }

    /// 3. Full Actor Replacement for Maximum Safety 🔒
    actor AppConfig {
        static let shared = AppConfig()
        var isDarkModeEnabled: Bool = false
    }

    /**
     To access this actor’s properties, you’ll use await to ensure asynchronous, thread-safe access:

     Task {
         let darkMode = await AppConfig.shared.isDarkModeEnabled
     }
     */
}
