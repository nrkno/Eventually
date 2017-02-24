//
//  ExecutionContext.swift
//  Eventually
//
//  Created by Johan Sørensen on 21/02/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import Foundation
import Dispatch

/// The GCD queue context in which a given Future operation should be performed
public enum ExecutionContext {
    /// The main queue, if already on the main queue the task is run immediately
    case main
    /// The background QoS queue
    case background
    /// A global queue with the given QoSClass
    case global(DispatchQoS.QoSClass)
    /// A queue of your choice
    case queue(DispatchQueue)

    internal var queue: DispatchQueue {
        switch self {
        case .main:
            return DispatchQueue.main
        case .background:
            return DispatchQueue.global(qos: .background)
        case .global(let qos):
            return DispatchQueue.global(qos: qos)
        case .queue(let queue):
            return queue
        }
    }

    internal func apply(execute: @escaping () -> Void) {
        switch (self, Thread.isMainThread) {
        case (.main, true):
            execute()
        default:
            queue.async {
                execute()
            }
        }
    }
}
