![Eventually logo](https://raw.githubusercontent.com/nrkno/Eventually/master/Assets/logo.png)

# Eventually

A Swift library implementing a simple Future (also known as Promise), which can be used to model and transform asynchronous results.

## Usage

Futures in Eventually can be used to wrap existing asynchronous APIs in a Future and to create new APIs that return a Future

```Swift
func operation(completion: (Int) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
        completion(42)
    }
}

Future<Int> { resolve in
    operation { value
        resolve(.success(value))
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

When initializing a Future the closure receives a "resolver", this resolver is simply a closure that you will call with a [FutureResult](/Sources/FutureResult.swift), a Result-like enum type that can be either `.success` or `.failure`. 

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

### Mapping values

With Eventually it is possible to `map()` one Future type to another, this allows us to compose and transform things easily

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
    resolve(.success("hello"))
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

Installation is supported for CocoaPods, Carthage, and the Swift Package Manager. For installation methods, please refer to that systems documentation. Eventually has no dependencies outside of GCD.

## License

See the LICENSE file
