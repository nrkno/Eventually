import Foundation
import Eventually
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

/*:
## Execution Contexts

Most of the methods takes an optional `on:` parameter that dictates on which ExecutionContext
The task should be performed on, the ExecutionContext is a shorthand way of specifying the queue
 */

//:First, create a Future that runs its resolve closure on a background queue
let backgroundFuture = Future<Double>(on: .background) { resolve in
    // runs on background queue
    resolve.success(42)
}

//: Then we transform (map) the value of the future, once it has a value, on our own queue
let queue = DispatchQueue(label: "no.nrk.Eventually.playground")
let mapped = backgroundFuture.map(on: .queue(queue)) { value in
    // Runs on our own queue
    return value * Double.pi
}

//: Then we get notified on the main thread (the default) if the future resolves with a successful value 
mapped.success(on: .main) { value in
        print("back on main thread the value is", value)
}

//: [Previous: Execution Contexts](@next)
