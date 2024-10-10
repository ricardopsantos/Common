//
//  Actor.swift
//  Common
//
//  Created by Ricardo Santos on 23/09/2024.
//

import Foundation

/**

 https://medium.com/@valentinjahanmanesh/swift-actors-in-depth-19c8b3dbd85a

 In Swift, an actor is a reference type introduced in Swift 5.5 as part of its advanced concurrency model.
 Its primary role is to prevent data races and ensure safe access to shared mutable state in concurrent programming environments

 By simply changing class to actor in our definition, we make the Account object thread-safe. This change, while minimal in syntax,
 has significant implications for how the object is accessed and manipulated in a concurrent environment.
 */
extension CommonLearnings {
    /// Here’s the crux: Suppose the first thread checks the balance and finds it sufficient (balance >= amount).
    /// But before it can deduct the amount, a context switch happens, and the second thread starts executing.
    /// This second thread also finds the balance sufficient because the first thread hasn’t completed its withdrawal yet.
    /// So, it proceeds to withdraw the money, leaving the balance at zero. Then, when the first thread resumes, it continues from
    /// where it left off — which is to withdraw the money, even though the balance has already been depleted by the second thread.
    actor Account {
        let accountNumber: String = "IBAN..." // A constant, non-isolated property
        var balance: Int = 20 // Current user balance is 20

        /// Non-isolated members allow certain parts of an actor to be accessed without the need for asynchronous calls or awaiting their turn in the actor’s task queue.
        nonisolated func getMaskedAccountNumber() -> String {
            String(repeating: "*", count: 12) + accountNumber.suffix(4)
        }

        func withdraw(amount: Int) {
            guard balance >= amount else { return }
            balance -= 1
        }
    }

    actor TransactionManager {
        let account: Account

        init(account: Account) {
            self.account = account
        }

        func performWithdrawal(amount: Int) async {
            await account.withdraw(amount: amount)
        }
    }

    static func usage() {
        let myAccount = Account()
        let manager = TransactionManager(account: myAccount)

        // Perform a withdrawal from TransactionManager Actor
        Task {
            // cross-actor reference
            await manager.performWithdrawal(amount: 10)
        }

        // Perform a withdrawal from outside any actor
        Task {
            // cross-actor reference
            await myAccount.withdraw(amount: 5)
        }
    }
}
