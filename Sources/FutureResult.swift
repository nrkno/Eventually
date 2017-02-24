//
//  FutureResult.swift
//  Eventually
//
//  Created by Johan Sørensen on 21/02/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import Foundation

/// Represents a Future result that can have only one of two states: .success (the value) or .failure (an error)
public enum FutureResult<T> {
    case success(T)
    case failure(Error)

    /// The value in case of .success
    public var value: T? {
        return map({ $0 })
    }

    /// The error in case of .failure
    public var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }

    /// If self is .success then the transform closure is run on the result, otherwise nil is returned
    public func map(_ transform: (T) -> T) -> T? {
        switch self {
        case .success(let value):
            return transform(value)
        case .failure:
            return nil
        }
    }
}
