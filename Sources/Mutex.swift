//
//  Mutex.swift
//  Eventually
//
//  Created by Johan Sørensen on 21/02/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

internal final class Mutex {
    private var mutex = pthread_mutex_t()

    init(){
        let res = pthread_mutex_init(&mutex, nil)
        if res != 0 {
            fatalError("failed to init mutex: \(strerror(res))")
        }
    }

    deinit {
        let res = pthread_mutex_destroy(&mutex)
        if res != 0 {
            print("failed to destroy mutex: \(strerror(res))")
        }
    }

    func lock() {
        try! aquire(pthread_mutex_lock(&mutex))
    }

    func unlock() {
        try! aquire(pthread_mutex_unlock(&mutex))
    }

    @discardableResult
    func locked<T>(_ task: () -> T) -> T {
        lock()
        defer { unlock() }
        return task()
    }

    private struct MutexError: Error {
        let message: String
    }

    private func aquire(_ item: @autoclosure () -> Int32) throws {
        let res = item()
        if res != 0 {
            throw MutexError(message: "\(strerror(res))")
        }
    }
}
