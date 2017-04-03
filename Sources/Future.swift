//
//  Future.swift
//  Eventually
//
//  Created by Johan Sørensen on 21/02/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import Foundation

/// A Future represent a value that has not yet been calculated, using this class you
/// observe and transform such a value when it has been materialized with a value
public final class Future<Value> {
    public var result: FutureResult<Value>?
    public var isCompleted: Bool { return result != nil }

    private var observers: [Observable<Value>] = []
    private let mutex = Mutex()
    private let resolveContext: ExecutionContext

    /// Creates a new future, call the provided resolver when the (async) task completes with
    /// either an FutureResult.success or FutureResult.failure in the case of errors
    ///
    /// - returns: a Future which can be passed around, mapped to another type or materialize its value once
    ///            the value is available
    /// - parameter on: The ExecutionContext on which this Future should be resolved. Defaults to main queue
    /// - parameter resolver: The body of the Future which received a resolve closure to be called 
    ///                       when the Future is realized
    ///
    /// ```swift
    /// Future<Int> { resolve in
    ///     someAsyncFunc { value in
    ///         resolve.success(value)
    ///     }
    /// }
    public init(on context: ExecutionContext = .main, resolver: @escaping (Resolve<Value>) -> Void) {
        self.result = nil
        self.resolveContext = context

        context.apply {
            let resolve = Resolve(closure: { result in
                self.complete(with: result)
            })
            resolver(resolve)
        }
    }

    /// Creates a new Future that can be resolve at a later time
    ///
    /// - returns: a Future which can be passed around, mapped to another type or materialize its value once
    ///            the value is available
    /// - parameter on: The ExecutionContext on which this Future should be resolved. Defaults to main queue
    /// ```swift
    /// let future = Future<Int>()
    /// ...
    /// future.resolve(success: value)
    public init(on context: ExecutionContext = .main) {
        self.result = nil
        self.resolveContext = context
    }

    /// Resolve the future with a successful value
    ///
    /// - parameter success: The value to complete the Future with
    public func resolve(success value: Value)  {
        self.resolveContext.apply {
            self.complete(with: .success(value))
        }
    }

    /// Attempts to resolve the future, turning any thrown errors into a failing future
    ///
    /// - parameter try: Closure to evaluate for a value, if an error is thrown the future is resolve as a failure
    public func resolve(try closure: @escaping () throws -> Value) {
        self.resolveContext.apply {
            do {
                let value = try closure()
                self.complete(with: .success(value))
            } catch {
                self.complete(with: .failure(error))
            }
        }
    }

    /// Resolve the future with an error value
    ///
    /// - parameter error: The error value to complete the Future with
    public func resolve(error: Error) {
        self.resolveContext.apply {
            self.complete(with: .failure(error))
        }
    }

    /// Calls the completion closure once the value of the Future is available to be materialized
    ///
    /// - parameter on: The ExecutionContext on which the completion closure should be called, defaults to .main
    /// - parameter completion: The closure which will receive the FutureResult once the Future is materialized
    /// - returns: A new chainable Future instance
    ///
    /// ```swift
    /// someFuture.then { result in
    /// switch result {
    /// case .success(let value):
    ///     // .. do something with the Value
    /// case .failure(let error):
    ///     // .. error handling
    /// }
    @discardableResult
    public func then(on context: ExecutionContext = .main, _ completion: @escaping (FutureResult<Value>) -> Void) -> Future<Value> {
        let observable = Observable<Value>(context: context, observer: completion)

        if let result = self.result {
            observable.call(result: result)
        } else {
            mutex.locked {
                self.observers.append(observable)
            }
        }

        return self
    }

    /// Calls the completion closure in case of a succesful Future completion
    ///
    /// - parameter on: The ExecutionContext on which the completion closure should be called, defaults to .main
    /// - parameter completion: The closure which will receive the resulting value once the Future is materialized
    ///                         to a successful value, otherwise in case of an error Result it will not be called
    /// - returns: A new chainable Future instance
    @discardableResult
    public func success(on context: ExecutionContext = .main, _ completion: @escaping (Value) -> Void) -> Future<Value> {
        return Future { resolve in
            self.then(on: context) { result in
                switch result {
                case .success(let value):
                    completion(value)
                    resolve.success(value)
                case .failure(let error):
                    resolve.failure(error)
                }
            }
        }
    }

    /// Calls the completion closure in case of a failure Future completion
    ///
    /// - parameter on: The ExecutionContext on which the completion closure should be called, defaults to .main
    /// - parameter completion: The closure which will receive the resulting error if the Future materializes 
    ///                         to an error, will not be called otherwise
    /// - returns: A new chainable Future instance
    @discardableResult
    public func failure(on context: ExecutionContext = .main, _ completion: @escaping (Error) -> Void) -> Future<Value> {
        return Future { resolve in
            self.then(on: context) { result in
                switch result {
                case .success(let value):
                    resolve.success(value)
                case .failure(let error):
                    completion(error)
                    resolve.failure(error)
                }
            }
        }
    }

    private func complete(with result: FutureResult<Value>) {
        guard !isCompleted else { return }

        self.result = result

        var observers = mutex.locked { () -> [Observable<Value>] in
            let reversed = Array(self.observers.reversed())
            self.observers.removeAll()
            return reversed
        }

        while let observer = observers.popLast() {
            observer.call(result: result)
        }
    }
}

/// :nodoc:
extension Future: CustomStringConvertible {
    public var description: String {
        return "<\(type(of: self)) result: \(String(describing: result))>"
    }
}
