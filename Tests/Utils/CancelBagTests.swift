//
//  CancelBagTests.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

import Testing
import Combine
@testable import Common

// Reference container for escaping closure tests
final class Box<T> {
    var value: T
    init(_ value: T) { self.value = value }
}

@Suite(.serialized)
struct CancelBagTests {

    // Helper: Creates a cancellable that toggles a flag when cancelled
    func makeCancellable(_ box: Box<Bool>) -> AnyCancellable {
        AnyCancellable { box.value = true }
    }

    // MARK: - Tests

    @Test
    func testStoreAutoReleased() {
        let flag = Box(false)
        let cancellable = makeCancellable(flag)
        let bag = CancelBag()

        cancellable.store(in: bag, autoRelease: true, subscriptionId: "A")

        #expect(bag.count == 1)
        #expect(flag.value == false) // should NOT be cancelled yet
    }

    @Test
    func testAutoReplaceSameId() {
        let first = Box(false)
        let second = Box(false)

        let bag = CancelBag()

        let c1 = makeCancellable(first)
        let c2 = makeCancellable(second)

        c1.store(in: bag, subscriptionId: "X")
        c2.store(in: bag, subscriptionId: "X") // replaces c1

        #expect(first.value == true)   // c1 cancelled
        #expect(second.value == false) // c2 alive
        #expect(bag.count == 1)
    }

    @Test
    func testRemoveById() {
        let flag = Box(false)
        let bag = CancelBag()

        let c = makeCancellable(flag)
        c.store(in: bag, subscriptionId: "Test")

        let removed = bag.remove(id: "Test")

        #expect(removed == true)
        #expect(flag.value == true)
        #expect(bag.count == 0)
    }

    @Test
    func testCancelWithPrefix() {
        let c1Flag = Box(false)
        let c2Flag = Box(false)

        let bag = CancelBag()

        let c1 = makeCancellable(c1Flag)
        let c2 = makeCancellable(c2Flag)

        c1.store(in: bag, subscriptionId: "network.load")
        c2.store(in: bag, subscriptionId: "network.save")

        bag.cancel(withPrefix: "network")

        #expect(c1Flag.value == true)
        #expect(c2Flag.value == true)
        #expect(bag.count == 0)
    }

    @Test
    func testCancelAll() {
        let f1 = Box(false)
        let f2 = Box(false)

        let bag = CancelBag()

        let c1 = makeCancellable(f1)
        let c2 = makeCancellable(f2)

        c1.store(in: bag, subscriptionId: "1")     // auto-release
        c2.store(in: bag, autoRelease: false)      // retained

        bag.cancelAll()

        #expect(f1.value == true)
        #expect(f2.value == true)
        #expect(bag.isEmpty)
    }
}
