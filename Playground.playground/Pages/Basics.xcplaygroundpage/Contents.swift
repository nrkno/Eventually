import Foundation
import Eventually
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

/*:
# Eventually

In order for this playground to work, make sure that you've opened the Eventually.xcworkspace workspace and then selected the playgound. Then build the Eventually-iOS scheme.

## Basics

### Basic usage & the Result type
*/

/*: A Future represents a value that has not yet materialized, once it is ready we'll call the `resolve` closure with either a `.success` or `.falure` depending on whether the Future resolves to some value or if it encountered an error along the way
 */
let basicFuture = Future<Int>(resolver: { resolve in
    resolve.success(42)
})

/*: At this point the future may or may not hold a value, so we can use `then()` to get notified when it resolves/materializes. We get delivered a Result enum type, which can hold either a `.success` or `.failure`
 */
basicFuture.then { result in
    switch result {
    case .success(let value):
        print("basicFuture is", value)
    case .failure(let error):
        print("basicFuture failed: ", error)
    }
}

//: ### Wrapping existing API

//: Do something expensive on a background queue, then bounce back to main
func advancedMathematics(base: Int, completion: @escaping (Int) -> Void) {
    DispatchQueue.global(qos: .background).async {
        let result = base * 2
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            completion(result)
        }
    }
}
advancedMathematics(base: 42) { value in
    // value is 84
}

//: Existing APIs can easily be wrapped to provide a Future simply by calling the resolve handler once the operation finishes
func futureMathematics(base: Int) -> Future<Int> {
    return Future { resolve in
        advancedMathematics(base: base, completion: { value in
            resolve.success(value)
        })
    }
}

let asyncFuture = futureMathematics(base: 42)
//: `success()` and `failure()` are provided as chainable shorthand methods
asyncFuture.success { value in
    print("ayncFuture is ", value)
}

//: ### Transforming Futures

//: The (successful) result of a Future can be mapped into another value. The transform only occurs when the Future value has materialized. Multiple `map()`s (and any other Future method) can be chained
asyncFuture
    .map({ $0 / 2})
    .map({ n in
        return "The meaning is \(n)"
    })
    .success { value in
        print("transformed future is ", value)
}

//: ### Alternative API

//: If it suits you implementation better you can use a non-closure based API to resolve Futures

let future = Future<Int>()
future.success { value in
    print(value)
}
future.resolve(success: 42)


//: [Next: Errors](@next)
