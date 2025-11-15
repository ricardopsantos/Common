import Foundation

public extension Thread {
    static var isMain: Bool {
        isMainThread
    }

    /// ⚠️ QoS does *not* indicate main thread; kept only for backward compatibility
    static var isMainThreadV2: Bool {
        Thread.current.qualityOfService == .userInteractive
    }

    static var info: String {
        """
        ⚡️ Thread: \(Thread.current.threadName)
        🏭 Queue:  \(Thread.current.queueName)
        """
    }

    var threadName: String {
        if isMainThread {
            return "main"
        }
        if let name = Thread.current.name, !name.isEmpty {
            return name
        }
        return description
    }

    var queueName: String {
        // Most reliable: GCD queue label
        let cString = __dispatch_queue_get_label(nil)
        if let name = String(validatingUTF8: cString), !name.isEmpty {
            return name
        }

        // OperationQueue label
        if let opName = OperationQueue.current?.name, !opName.isEmpty {
            return opName
        }

        // Underlying queue label (rare, but valid)
        if let underlying = OperationQueue.current?.underlyingQueue {
            let label = underlying.label
            if !label.isEmpty {
                return label
            }
        }

        return "n/a"
    }
}
