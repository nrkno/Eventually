//
//  ExecutionContext.swift
//  Eventually
//
//  Created by Johan Sørensen on 21/02/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import Foundation
import Dispatch

public enum ExecutionContext {
    case main
    case background
    case global(DispatchQoS.QoSClass)
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
