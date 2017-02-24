//
//  Observable.swift
//  Eventually
//
//  Created by Johan Sørensen on 21/02/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import Foundation

internal final class Observable<Value> {
    let context: ExecutionContext
    private let observer: (FutureResult<Value>) -> Void

    init(context: ExecutionContext, observer: @escaping (FutureResult<Value>) -> Void) {
        self.context = context
        self.observer = observer
    }

    func call(result: FutureResult<Value>) {
        context.apply {
            self.observer(result)
        }
    }
}
