//
//  Future+Operations.swift
//  Eventually
//
//  Created by Johan Sørensen on 03/04/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import Foundation

extension Future {
    /// Maps the materialized value to type `U`
    /// - parameter on: The ExecutionContext on which the completion closure should be called, defaults to .main
    /// - parameter transform: The transform closure that should map the successful value
    /// - returns: A new chainable Future instance
    ///
    /// ```swift
    /// someFuture.map({ (age: Int) -> String
    ///     return "Age: \(age)
    /// }).success { print($0) }
    @discardableResult
    public func map<U>(on context: ExecutionContext = .main, _ transform: @escaping (Value) -> U) -> Future<U> {
        return Future<U> { resolve in
            self.then(on: context) { result in
                switch result {
                case .success(let value):
                    resolve.success(transform(value))
                case .failure(let error):
                    resolve.failure(error)
                }
            }
        }
    }

    /// Combines the successful result of one future with something that takes the successful result as a
    /// parameter and returns another future
    @discardableResult
    public func combine<U>(with other: @escaping (Value) -> Future<U>) -> Future<U> {
        let final = Future<U>()
        then { result in
            switch result {
            case .success(let value):
                other(value)
                    .success { value in
                        final.resolve(success: value)
                    }
                    .failure { error in
                        final.resolve(error: error)
                }
            case .failure(let error):
                final.resolve(error: error)
            }

        }
        return final
    }

    /// Returns a Future of type `T` that returns when all the supplied Future of type `T` finishes, or if a
    /// Future returns a failure
    ///
    /// - parameter futures: List of Futures of type `T`
    ///
    /// ```swift
    /// Future<Int>.all([one(), two(), three()]).success { values in
    ///     // values is an array containing the .success values from the one(), two(), three() futures
    /// }
    public static func all<T, U: Sequence>(_ futures: U) -> Future<[T]> where U.Iterator.Element == Future<T> {
        return Future<[T]>(on: .background) { resolve in
            let futures = Array(futures)
            let mutex = Mutex()
            var remaining = futures.count
            for future in futures {
                future.success(on: .background) { value in
                    mutex.locked { remaining -= 1 }
                    if remaining <= 0 {
                        let values = futures.flatMap({ $0.result?.value })
                        resolve.success(values)
                    }
                    }.failure(on: .background) { error in
                        resolve.failure(error)
                }
            }
        }
    }
}