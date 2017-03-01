import UIKit
import Eventually
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

//: ## error handling

enum Trouble: Error {
    case fail
}

let failingFuture = Future<Int> { resolve in
    resolve.failure(Trouble.fail)
}

//: Switching on the Result type

failingFuture.then { result in
    switch result {
    case .success(let value):
        print("failingFuture is", value)
    case .failure(let error):
        print("failingFuture failed: ", error)
    }
}

//: The success() + failure() helpers

failingFuture.map { value in
    return "the value is \(value)"
}.success { value in
    print(value)
}.failure { error in
    print("Error: ", error)
}


//: [Previous: Basics](@previous) | [Previous: Execution Contexts](@next)
