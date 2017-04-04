![Eventually logo](/Assets/logo.png)

# Eventually

A Swift implementation of a [Future](https://en.wikipedia.org/wiki/Futures_and_promises), which can be used to model and transform asynchronous results while making it easy to bounce results between dispatch queues

## Usage

Futures in Eventually can be used to wrap existing APIs, or to create new APIs using Futures

```Swift
func operation(completion: (Int) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
        completion(42)
    }
}

Future<Int> { resolve in
    operation { value
        resolve.success(value)
    }
}.then { result in
    switch result {
    case .success(let value):
        print("value is", value) // "value is 42"
    case .failure(let error):
        print("something went wrong:", error)
    }
}
```

When initializing a Future the closure receives a "resolver", this resolver is simply a closure that you will call with a [FutureResult](/Sources/FutureResult.swift), a Result enum type which can be either `.success` or `.failure`.

There's also a couple of short-hand methods available

```swift
func calculateAge() -> Future<Int> {
    // ...
}
calculateAge().success { (value: Int) in
    print("Success value from calling calculateAge() is", value)
}.failure { error in
    print(The Future returned by calculateAge() gave us an error:", error)
}
```

A non-closure based API for resolving futures is also available

```swift
let future = Future<Int>()
future.success { value in
    ...
}
future.resolve(success: age)
```

### Mapping values

With Eventually it is possible to `map()` one Future type to another, allowing us to compose and transform things easily

```swift
calculateAge().map({ (value: Int) -> String in
    return "Age is \(age)"
}).success { value in
    print(value) // "Age is 42"
}
```

Like always, chaining is possible so multiple transforms can be done

### Evaluation Contexts

Most of the methods operating on a Future accepts an [EvaluationContext](/Sources/EvaluationContext.swift) that describes what GCD queue the operation should be called on

```swift
Future<String>(on: .background) { resolve
    // Performed on a background queue (eg `DispatchQueue.global(qos: .background)`)
    resolve.success("hello"))
}.map(on: .queue(someCustomQueue)) { value in
    // will be called on the supplied DispatchQueue (`someCustomQueue`)
    return value + " world"
}.map(on: .main) { value in
    // Mapping occurs on the main thread
    let label = UILabel()
    label.text = value
    return text
}.success { label in
    // default is the `.main` context
    self.view.addSubview(label)
}
```

## Installation

Eventually is available as a CocoaPod (`pod 'Eventually'`) and the Swift Package Manager. Framework installation is also available by dragging the Eventually.xcodeproj into your project or via Carthage.

Eventually has no dependencies outside of Foundation and Dispatch (GCD)

## License

See the LICENSE file
