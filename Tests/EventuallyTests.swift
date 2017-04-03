//
//  EventuallyTests.swift
//  EventuallyTests
//
//  Created by Johan Sørensen on 21/02/2017.
//  Copyright © 2017 NRK. All rights reserved.
//

import XCTest
import Eventually

class EventuallyTests: XCTestCase {
    func testBasics() {
        let stringFuture = Future<String> { resolve in
            resolve.success("hello")
        }

        XCTAssert(stringFuture.isCompleted)
        switch stringFuture.result! {
        case .success(let value):
            XCTAssertEqual(value, "hello")
        case .failure:
            XCTFail()
        }
    }

    func testThen() {
        successFuture().then { result in
            switch result {
            case .success(let value):
                XCTAssertEqual(value, 42)
            case .failure:
                XCTFail()
            }
        }

        failingFuture().then { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssert(error is TestError)
            }
        }
    }

    func testAsyncSuccess() {
        let wait = expectation(description: "async")

        successAsyncFuture().then { result in
            XCTAssertEqual(result.value, Optional(42))
            XCTAssertNil(result.error)
            wait.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testSuccessFailureSugar() {
        let wait = expectation(description: "async")

        successAsyncFuture()
            .success { value in
                XCTAssertEqual(value, 42)
                wait.fulfill()
            }.failure { _ in
                XCTFail("should never be reached")
            }
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testFailingSuccessFailureSugar() {
        let wait = expectation(description: "async")

        failingAsyncFuture()
            .success { _ in
                XCTFail("should never be reached")
            }.failure { error in
                XCTAssert(error is TestError)
                wait.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testAsyncFailure() {
        let wait = expectation(description: "async")

        failingAsyncFuture().then { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            wait.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testResolvingOnNonMailExecutionContext() {
        let future = Future<Int>(on: .background) { resolve in
            XCTAssertFalse(Thread.isMainThread)
            self.operation(completion: { val in
                resolve.success(val)
            })
        }

        let wait = expectation(description: "async")

        future.then { result in
            XCTAssertTrue(Thread.isMainThread)
            wait.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testFulfillingMailExecutionContext() {
        let future = Future<Int>(on: .main) { resolve in
            XCTAssertTrue(Thread.isMainThread)
            self.operation(completion: { val in
                resolve.success(val)
            })
        }

        let wait = expectation(description: "async")

        future.then(on: .background) { result in
            XCTAssertFalse(Thread.isMainThread)
            wait.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testAsyncMapping() {
        let wait = expectation(description: "async")

        successAsyncFuture()
            .map({ $0 * 2 })
            .then({ result in
                XCTAssertEqual(result.value, Optional(84))
                wait.fulfill()
            })

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testAsyncMappingOnContext() {
        let wait = expectation(description: "async")

        successAsyncFuture()
            .map(on: .background, { (value: Int) -> Int in
                XCTAssertFalse(Thread.isMainThread)
                return value * 2
            })
            .then({ result in
                XCTAssertEqual(result.value, Optional(84))
                wait.fulfill()
            })

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testAll() {
        let wait = expectation(description: "async")

        var count = 0
        Future<Int>.all([
            successAsyncFuture(value: 2).success({ _ in count += 1 }),
            successAsyncFuture(value: 4).success({ _ in count += 1 }),
            successAsyncFuture(value: 6).success({ _ in count += 1 }),
        ]).success { values in
            // all done
            XCTAssertEqual(count, 3)
            XCTAssertEqual(values, [2, 4, 6])
            wait.fulfill()
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testAllFailure() {
        let wait = expectation(description: "async")

        var count = 0
        func run() -> Future<Int> {
            return Future { resolve in
                DispatchQueue.global().async {
                    count += 1
                    resolve.success(1)
                }
            }
        }

        Future<Int>.all([
            run(),
            failingFuture(),
            run(),
        ]).failure { error in
            XCTAssertEqual(count, 2)
            wait.fulfill()
        }

        waitForExpectations(timeout: 0.5)
    }

    func testNonClosureResolveSuccess() {
        let future = Future<Int>()

        let wait = expectation(description: "async")
        future.success { value in
            XCTAssertEqual(value, 42)
            wait.fulfill()
        }

        future.resolve(success: 42)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testNonClosureResolveFailure() {
        let future = Future<Int>()

        let wait = expectation(description: "async")
        future.failure { error in
            XCTAssert(error is TestError)
            wait.fulfill()
        }

        future.resolve(error: TestError.fail)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testFuturesCanOnlyBeResolvedOnce() {
        let future = Future<Int>()
        future.resolve(success: 42)
        XCTAssertEqual(future.result!.value, 42)
        future.resolve(success: 666)
        XCTAssertEqual(future.result!.value, 42)
    }

    func testThrowingFuture() {
        let wait1 = expectation(description: "async")
        let successFuture = Future<Int>()
        successFuture.success { value in
            XCTAssertEqual(value, 42)
            wait1.fulfill()
        }
        successFuture.resolve(try: {
            return 42
        })

        let wait2 = expectation(description: "async2")
        let failingFuture = Future<Int>()
        failingFuture.failure { error in
            XCTAssert(failingFuture.result!.error is TestError)
            XCTAssertEqual(failingFuture.result!.error as! TestError, TestError.fail)
            wait2.fulfill()
        }
        failingFuture.resolve(try: {
            throw TestError.fail
        })

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testCombine() {
        func gen(shouldFail: Bool = false) -> Future<Int> {
            let future = Future<Int>()
            if !shouldFail {
                future.resolve(success: 42)
            } else {
                future.resolve(error: TestError.fail)
            }

            return future
        }
        func stringy(value: Int) -> Future<String> {
            return Future(on: .background) { resolve in
                resolve.success("value is \(value)")
            }
        }
        func stringyFail(value: Int) -> Future<String> {
            return Future(on: .background) { resolve in
                resolve.failure(TestError.fail2)
            }
        }

        let wait1 = expectation(description: "async")
        gen().combine(with: stringy).success { value in
            XCTAssertEqual("value is 42", value)
            wait1.fulfill()
        }

        let wait2 = expectation(description: "async")
        gen(shouldFail: true).combine(with: stringy).success { value in
            XCTFail()
        }.failure { error in
            XCTAssert(error is TestError)
            XCTAssertEqual(error as! TestError, TestError.fail)
            wait2.fulfill()
        }

        let wait3 = expectation(description: "async")
        gen().combine(with: stringyFail).success { value in
            XCTFail()
        }.failure { error in
            XCTAssert(error is TestError)
            XCTAssertEqual(error as! TestError, TestError.fail2)
            wait3.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    // MARK: - Helpers

    func operation(value: Int = 42, completion: @escaping (Int) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(256)) {
            completion(value)
        }
    }

    func successAsyncFuture(value: Int = 42) -> Future<Int> {
        return Future { resolve in
            self.operation(value: value, completion: { val in
                resolve.success(val)
            })
        }
    }

    func successFuture() -> Future<Int> {
        return Future { resolve in
            resolve.success(42)
        }
    }

    enum TestError: Error {
        case fail
        case fail2
    }

    func failingFuture() -> Future<Int> {
        return Future<Int> { resolve in
            resolve.failure(TestError.fail)
        }
    }

    func failingAsyncFuture() -> Future<Int> {
        return Future<Int> { resolve in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(256)) {
                resolve.failure(TestError.fail)
            }
        }
    }
}
