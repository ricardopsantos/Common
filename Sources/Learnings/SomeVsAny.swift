//
//  SomeVsAny.swift
//  Common
//
//  Created by Ricardo Santos on 07/08/2024.
//

import Foundation
import SwiftUI

// https://paigeshin1991.medium.com/swift-whats-the-difference-between-some-book-vs-any-book-394333e22f77
// https://medium.com/@bancarel.paul/swift-6-lets-take-some-time-to-avoid-any-confusion-14fb3497eaa6

protocol SomeVsAnyShapeProtocol {
    func draw()
}

public extension CommonLearnings {
    struct SomeVsAny {
        /**
         __TLDR__

         In Swift, an _existential type_ (as opposed to generic types and concrete types) is a type that can hold any value that conforms to a given protocol

         `any`:   __existential type__  (a box with a bird inside) is used to work with values of any type that conforms to a protocol, providing a more flexible approach where the exact type can vary.
         `some` : __Opaque Type__ - (a kind of bird) Existing is used to provide an abstract type while hiding the specific implementation details, ensuring that the type conforms to a protocol but keeping it opaque.

         Using `any`, __less performant__, means you want to use a box to manipulate your object. Opening this box at runtime will have a cost :)
         Using `some` means you wouldn’t use box to manipulate your object, it’s better for performance but not always possible depending on what you’re trying to describe.

         __Opaque Type__ : This is useful when you want use a type without revealing the specific type details but still ensure it conforms to a protocol
         - Abstraction: You can hide implementation details of a type.
         - Performance: The compiler knows the underlying type, which allows it to optimize the code.
         - Consistency: The function always returns the same type (though hidden), and the compiler enforces this.
         */

        struct Circle: SomeVsAnyShapeProtocol {
            func draw() {
                Common_Logs.debug("Drawing a circle")
            }
        }

        struct Square: SomeVsAnyShapeProtocol {
            func draw() {
                Common_Logs.debug("Drawing a square")
            }
        }

        func printShape(_ shape: any SomeVsAnyShapeProtocol) {
            shape.draw()
        }

        // Function returning an Opaque Types
        func makeShape() -> some SomeVsAnyShapeProtocol {
            Circle() // or return Square()
        }

        //
        // MARK: - Difference Between Opaque Types and Protocol Types
        //

        // Opaque types (some) hide the type but guarantee a single, consistent underlying type.
        // Protocol types (any) allow multiple types to conform to the protocol, but the underlying type may vary.
        // In this case, makeShape() returns a protocol type (Shape), and the specific
        // type returned can vary at runtime, which means the COMPILES LOOSES OPTIMISATION OPPORTUNITIES.
        func makeShape() -> SomeVsAnyShapeProtocol {
            if Bool.random() {
                return Circle()
            } else {
                return Square()
            }
        }
    }
}
