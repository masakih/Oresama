//
//  FutureTests.swift
//  testXCTestTests
//
//  Created by Hori,Masaki on 2018/01/15.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

import XCTest
@testable import Oresama

enum FutureTestError: Error {
    
    case testError
    
    case testError2
}

class FutureTests: XCTestCase {
    
    func testAsynchronus() {
        
        let ex = expectation(description: "Future")
        
        var first = true
        
        Future<Int> {
            sleep(1)
            first = false
            
            return 1
            }
            .onSuccess { _ in
                ex.fulfill()
        }
        
        XCTAssertTrue(first)
        
        waitForExpectations(timeout: 2)
    }
    
    func testSuccess() {
        
        let ex = expectation(description: "Future")
        Future<Int>(.value(5))
            .onSuccess { val in
                guard val == 5 else { return XCTFail("Fugaaaaaaaaa") }
                
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testSuccess2() {
        
        let ex = expectation(description: "Future")
        let ex2 = expectation(description: "Future2")
        Future(5)
            .onSuccess { val in
                guard val == 5 else { return XCTFail("Fugaaaaaaaaa") }
                
                ex.fulfill()
            }
            .onSuccess { _ in
                ex2.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
                ex2.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testAsynchronousSuccess() {
        
        let ex = expectation(description: "Future")
        Future<Int> {
            sleep(1)
            
            return 5
            }
            .onSuccess { val in
                guard val == 5 else { return XCTFail("Fugaaaaaaaaa") }
                
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testFailure() {
        
        let ex = expectation(description: "Future")
        Future<Int>(FutureTestError.testError)
            .onSuccess { _ in
                XCTFail("Fugaaaaaa")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testFailure2() {
        
        let ex = expectation(description: "Future")
        let ex2 = expectation(description: "Future2")
        Future<Int>(FutureTestError.testError)
            .onSuccess { _ in
                XCTFail("Fugaaaaaa")
                ex.fulfill()
                ex2.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
            }
            .onFailure { _ in
                ex2.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testAsynchronousFailure() {
        
        let ex = expectation(description: "Future")
        Future<Int> {
            sleep(1)
            throw FutureTestError.testError
            }
            .onSuccess { _ in
                XCTFail("Fugaaaaaa")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testIsCompleted() {

        let f = Future<Int>(3)
        XCTAssertTrue(f.isCompleted)
        let ff = Future<Int>()
        XCTAssertFalse(ff.isCompleted)
    }
    
    func testAwait() {
        
        let f = Future<Int> {
            sleep(1)
            
            return 1000
        }
        
        XCTAssertEqual(f.await().value!.value!, 1000)
    }
    
    func testAwait2ndTime() {
        
        let f = Future<Int> {
            sleep(1)
            
            return 1000
        }
        
        XCTAssertEqual(f.await().await().value!.value!, 1000)
    }
    
    func testAwait3rdTime() {
        
        let f = Future<Int> {
            sleep(1)
            
            return 1000
        }
        
        XCTAssertEqual(f.await().await().await().value!.value!, 1000)
    }
    
    func testTransform() {
        
        Future<String> { () -> String in
            sleep(1)
            
            return "Hoge"
            }
            .transform({ (_: String) -> String in "Fuga" }, { _ -> Error in FutureTestError.testError })
            .onSuccess { val in
                
                XCTAssertEqual(val, "Fuga")
            }
            .onFailure { error in
                
                XCTFail("Hoge: \(error)")
        }
    }
    
    func testTransform2() {
        
        Future<String>(FutureTestError.testError)
            .transform({ (_: String) -> String in "Fuga" }, { _ -> Error in FutureTestError.testError2 })
            .onSuccess { _ in
                
                XCTFail("testTransform2")
            }
            .onFailure { error in
                
                guard let err = error as? FutureTestError else {
                    
                    XCTFail("Error is no FutureTestError.")
                    
                    return
                }
                
                XCTAssertEqual(err, FutureTestError.testError2)
        }
    }
    
    func testMap() {
        
        let ex = expectation(description: "Future")
        Future<String> {
            sleep(1)
            
            return "Hoge"
            }
            .map { $0.count }
            .onSuccess { _ in
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testMapFailure() {
        
        let ex = expectation(description: "Future")
        Future<String>(FutureTestError.testError)
            .map { $0.count }
            .onSuccess { _ in
                XCTFail("Hoge")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testFlatMap() {
        
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int> {
            sleep(1)
            
            return 1
        }
        
        Future<Int>(2)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .onSuccess { val in
                if val != 2 {
                    XCTFail("Must not reach.")
                }
                ex.fulfill()
            }
            .onFailure { _ in
                XCTFail("Must not reach.")
                ex.fulfill()
        }

        waitForExpectations(timeout: 2)
    }
    
    func testFlatMapFailure1() {
        
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int>(FutureTestError.testError)
        
        Future(2)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .onSuccess { _ in
                XCTFail("Must not reach.")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testFlatMapFailure2() {
        
        let ex = expectation(description: "Future")
        
        let f1 = Future(1)
        
        Future<Int>(FutureTestError.testError)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .onSuccess { _ in
                XCTFail("Must not reach.")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testFlatMapFailure3() {
        
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int>(FutureTestError.testError)
        
        Future<Int>(FutureTestError.testError)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .onSuccess { _ in
                XCTFail("Must not reach.")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testFilter() {
        
        let ex = expectation(description: "Future")
        Future<Int> {
            sleep(1)
            
            return 5
            }
            .filter { $0 == 5}
            .onSuccess { _ in
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testFilterFailure() {
        
        let ex = expectation(description: "Future")
        Future<Int> {
            sleep(1)
            
            return 5
            }
            .filter { $0 > 5}
            .onSuccess { _ in
                XCTFail("Hogeeeeeeee")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testRecover() {
        
        let ex = expectation(description: "Future")
        
        Future<Int>(FutureTestError.testError)
            .recover {
                guard let e = $0 as? FutureTestError,
                    e == FutureTestError.testError else {
                        throw $0
                }
                
                return 10
            }
            .onSuccess {
                XCTAssertEqual($0, 10)
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testRecoverThrow() {
        
        let ex = expectation(description: "Future")
        
        Future<Int>(FutureTestError.testError)
            .recover { _ in
                throw FutureTestError.testError2
            }
            .onSuccess {
                XCTFail("Fuga: \($0)")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testRecoverFailure1() {
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int>(FutureTestError.testError)
        
        Future(2)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .recover { _ in -1000 }
            .onSuccess { val in
                if val > 0 {
                    XCTFail("Must not reach.")
                }
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    func testRecoverFailure2() {
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int> {
            sleep(1)
            
            return 1
        }
        
        Future<Int>(FutureTestError.testError)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .recover { _ in -10000 }
            .onSuccess { val in
                if val > 0 {
                    XCTFail("Must not reach.")
                }
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testRecoverSuccess() {
        
        let ex = expectation(description: "Future")
        
        Future<Int>(5)
            .recover {
                guard let e = $0 as? FutureTestError,
                    e == FutureTestError.testError else {
                        throw $0
                }
                
                return 10
            }
            .onSuccess {
                XCTAssertEqual($0, 5)
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    
    func testRecoverWith() {
        
        let ex = expectation(description: "Future")
        
        Future<Int>(FutureTestError.testError)
            .recoverWith { error in
                Future {
                    guard let e = error as? FutureTestError,
                        e == FutureTestError.testError else {
                            throw error
                    }
                    
                    return 10
                }
            }
            .onSuccess {
                XCTAssertEqual($0, 10)
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testRecoverWithThrow() {
        
        let ex = expectation(description: "Future")
        
        Future<Int>(FutureTestError.testError)
            .recoverWith { _ in
                Future(FutureTestError.testError2)
            }
            .onSuccess {
                XCTFail("Fuga: \($0)")
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testRecoverWithFailure1() {
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int>(FutureTestError.testError)
        
        Future(2)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .recoverWith { _ in Future(-1000) }
            .onSuccess { val in
                if val > 0 {
                    XCTFail("Must not reach.")
                }
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    func testRecoverWithFailure2() {
        let ex = expectation(description: "Future")
        
        let f1 = Future<Int> {
            sleep(1)
            
            return 1
        }
        
        Future<Int>(FutureTestError.testError)
            .flatMap { n1 in f1.map { n2 in n1 * n2 } }
            .recoverWith { _ in Future(-10000) }
            .onSuccess { val in
                if val > 0 {
                    XCTFail("Must not reach.")
                }
                ex.fulfill()
            }
            .onFailure { _ in
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testRecoverWithSuccess() {
        
        let ex = expectation(description: "Future")
        
        Future<Int>(5)
            .recoverWith { error in
                Future {
                    guard let e = error as? FutureTestError,
                        e == FutureTestError.testError else {
                            throw error
                    }
                    
                    return 10
                }
            }
            .onSuccess {
                XCTAssertEqual($0, 5)
                ex.fulfill()
            }
            .onFailure { error in
                XCTFail("Hoge: \(error)")
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testAndThen() {
        
        let ex = expectation(description: "Future")
        
        var v = 0
        
        Future<Int>(6)
            .andThen { _ in
                guard v == 0 else {
                    XCTFail("Must not reach.")
                    
                    return
                }
                sleep(1)
                v = 4
            }
            .andThen { _ in
                guard v == 4 else {
                    XCTFail("Must not reach.")
                    
                    return
                }
                sleep(1)
                v = 5
            }
            .andThen { _ in
                guard v == 5 else {
                    XCTFail("Must not reach.")
                    
                    return
                }
                ex.fulfill()
            }
            .onSuccess {
                guard $0 == 6 else {
                    XCTFail("Must not reach.")
                    
                    return
                }
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testEquatable() {
        
        let future1 = Future(1)
        let future2 = Future(1)
        let future3 = Future(2)
        let future4 = Future<Int>(NSError(domain: "hoge", code: 0, userInfo: nil))
        let future5 = Future<Int>(NSError(domain: "hoge", code: 0, userInfo: nil))
        let future6 = Future<Int>(NSError(domain: "hoge", code: 1, userInfo: nil))
        
        XCTAssertEqual(future1, future2)
        XCTAssertNotEqual(future1, future3)
        
        XCTAssertEqual(future4, future5)
        XCTAssertNotEqual(future4, future6)
        
        XCTAssertNotEqual(future4, future1)
    }
    
    func testFunctor() {
        
        func i<T>(_ x: T) -> T { return x }
        
        let future = Future(1)
        
        XCTAssertEqual(future.map(i), i(future))
        
        ///
        
        func f(_ j: Int) -> String {
            
            return String(j)
        }
        func g(_ s: String) -> Double {
            
            return Double(s)!
        }
        
        XCTAssertEqual(future.map({ g(f($0)) }),
                       future.map(f).map(g))
    }
    
    func testMonad() {
        
        let value = 1
        
        func f(_ i: Int) -> Future<String> {
            
            return Future(String(i))
        }
        
        XCTAssertEqual(Future(value).flatMap(f),
                       f(value))
        
        ///
        let future = Future(2)
        
        XCTAssertEqual(future.flatMap({ Future($0) }),
                       future)
        
        ///
        func g(_ s: String) -> Future<Double> {
            
            return Future(Double(s)!)
        }
        
        XCTAssertEqual(future.flatMap({ f($0).flatMap(g) }),
                       future.flatMap(f).flatMap(g))
    }
}
