//
//  Created by Ricardo Santos on 15/08/2024.
//

import Foundation

// https://medium.com/@harshaag99/understanding-arrays-thread-safety-using-nslock-and-dispatch-barrier-in-swift-25997f6f7385

struct NSLockVsDispatchBarrier {
    /**
      `NSLock` is like a traffic light system for your array. When one thread (or person) wants to access or modify the array,
      it locks the array so that no other thread can touch it until the first one is done.

      `NSLock` is a traditional locking mechanism that ensures only one thread can access a critical section of code at a time.
      When a thread locks an object, no other thread can access the locked resource until it is unlocked. It's simple to implement but
      can be slower if there are frequent reads, as it blocks both reads and writes.

      ---

      `Dispatch Barrier` is another tool for thread safety, but it’s best used when you’re working
      with concurrent (multiple) threads that need to read and write to your array. It allows multiple threads to read from the array at
      the same time but ensures that only one thread can write (modify) at a time.

      `Dispatch Barrier` is used with concurrent dispatch queues. It allows multiple threads to read from a
      shared resource simultaneously, which improves performance in read-heavy scenarios. However, when a write operation
      is submitted using a barrier, it ensures no other reads or writes can occur until the write is finished. It’s more efficient than
      NSLock for scenarios with many reads and fewer writes, as it doesn’t block reads unless a write is happening.

     ---

      `NSLock` is simpler and__ better for single-threaded__ tasks where you just want to make sure one thread accesses the array at a time.
      `Dispatch Barrier` is more efficient when you have __multiple threads frequently reading the array__, as it allows many threads to read
      simultaneously while ensuring only one can write.
      */

    /// Here, whenever a thread wants to append, remove, or get an item from the array, we lock the array
    /// to ensure that no other thread can perform an action at the same time.
    class ThreadSafeArrayNSLock<T> {
        private var array = [T]()
        private let lock = NSLock()

        func append(_ element: T) {
            lock.lock() // Block other threads
            array.append(element)
            lock.unlock() // Allow other threads to proceed
        }

        func remove(at index: Int) -> T? {
            lock.lock()
            defer { lock.unlock() } // Unlock after the method finishes
            return index < array.count ? array.remove(at: index) : nil
        }

        func get(at index: Int) -> T? {
            lock.lock()
            defer { lock.unlock() }
            return index < array.count ? array[index] : nil
        }
    }

    /// In this example, multiple threads can read from the array simultaneously, but when a thread tries to write
    /// (add or remove items), it blocks all other reads and writes until it’s done.
    class ThreadSafeArrayNSLockDispatchBarrier<T> {
        private var array = [T]()
        private let queue = DispatchQueue.synchronizedQueue(label: "")

        func append(_ element: T) {
            queue.async(flags: .barrier) { // Block other threads during a write
                self.array.append(element)
            }
        }

        func remove(at index: Int) -> T? {
            var result: T?
            queue.async(flags: .barrier) {
                if index < self.array.count {
                    result = self.array.remove(at: index)
                }
            }
            return result
        }

        func get(at index: Int) -> T? {
            var result: T?
            queue.sync {
                if index < self.array.count {
                    result = self.array[index]
                }
            }
            return result
        }
    }
}
