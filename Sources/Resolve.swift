//
//  Resolve.swift
//  Eventually
//
//  Created by Johan Sørensen on 01/03/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import Foundation

/// Used to resolve a future, giving it either a success or a failure value.
/// Note: mostly exist to give a slightly more fluid api when resolving a future
public struct Resolve<T> {
    internal let closure: ((FutureResult<T>) -> Void)

    /// Resolves with a successful value
    public func success(_ value: T) {
        closure(.success(value))
    }

    // Resolves with an error
    public func failure(_ error: Error) {
        closure(.failure(error))
    }
}
