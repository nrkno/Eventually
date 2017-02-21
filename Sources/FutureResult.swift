//
//  FutureResult.swift
//  Eventually
//
//  Created by Johan Sørensen on 21/02/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import Foundation

public enum FutureResult<T> {
    case success(T)
    case failure(Error)

    public var value: T? {
        return map({ $0 })
    }

    public var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }

    public func map(_ transform: (T) -> T) -> T? {
        switch self {
        case .success(let value):
            return transform(value)
        case .failure:
            return nil
        }
    }

    public func flatMap(_ transform: (T) -> T?) -> T? {
        switch self {
        case .success(let value):
            return transform(value).flatMap({ $0 })
        case .failure:
            return nil
        }
    }
}
