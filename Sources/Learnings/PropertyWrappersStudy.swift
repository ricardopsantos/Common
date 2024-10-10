//
//  File.swift
//  Common
//
//  Created by Ricardo Santos on 24/09/2024.
//

import Foundation

/**

 In Swift, @propertyWrapper is a language feature that allows you to define a reusable piece of code to manage
 the access and storage of a property. It is introduced in Swift 5.1 and it simplifies the implementation of common
 property behaviors, such as lazy initialization, property observation, and validation.

 __If you’re not familiar with Property Wrappers in Swift, it’s not a big deal:__
 * We created a struct;
 * Added @propertyWrapper before its declaration;
 * Every Property Wrapper has to have wrappedValue.;
 */

extension CommonLearnings {
    struct PropertyWrappersStudy {}
}

//
// MARK: - Basics
//
extension CommonLearnings.PropertyWrappersStudy {
    /**
     `wrappedValue`: This property represents the value that is actually stored by the wrapper.
     It is the value that will be returned when the property is accessed using dot notation.

     `projectedValue`: This property is used to provide additional functionality to the wrapper by returning
     a separate value that can be used to access or modify the wrapped value. It is accessed using the
     dollar sign $ followed by the property name.
     */
    @propertyWrapper
    struct SamplePropertyWrapper1 {
        var wrappedValue: String
        var projectedValue: Int {
            wrappedValue.count
        }
    }

    struct SamplePropertyWrapper1Usage {
        @SamplePropertyWrapper1 var samplePropertyWrapper1: String = "Hello, world!"

        func usage() {
            // prints "Hello, world!"
            Common_Logs.debug(samplePropertyWrapper1)

            // prints the projected value, which is 13 (the length of "Hello, world!")
            Common_Logs.debug($samplePropertyWrapper1)
        }
    }
}
