//
//  PromiseTest.swift
//  OresamaTests
//
//  Created by Hori,Masaki on 2018/10/22.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import XCTest
@testable import Oresama

class PromiseTest: XCTestCase {
    
    let testError = NSError(domain: "PromiseTest", code: -100, userInfo: nil)

    func testCompleteSuccess() {
        
        let ex = expectation(description: "Promise")
        
        let promise = Promise<Int>()
        promise.complete(.value(1))
        promise
        .future
            .onSuccess { val in
                
                XCTAssertEqual(1, val)
                
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 0)
    }
    
    func testCompleteFailure() {
        
        let ex = expectation(description: "Promise")
        
        let promise = Promise<Int>()
        promise.complete(.error(testError))
        promise
            .future
            .onFailure { error in
                
                XCTAssertEqual(error as NSError, self.testError)
                
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 0)
    }
    
    func testSuccess() {
        
        let ex = expectation(description: "Promise")
        
        let promise = Promise<Int>()
        promise.success(1)
        promise
            .future
            .onSuccess { val in
                
                XCTAssertEqual(1, val)
                
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 0)
    }
    
    func testFailure() {
        
        let ex = expectation(description: "Promise")
        
        let promise = Promise<Int>()
        promise.failure(testError)
        promise
            .future
            .onFailure { error in
                
                XCTAssertEqual(error as NSError, self.testError)
                
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 0)
    }
    
    func testCompleteFunc() {
        
        let ex = expectation(description: "Promise")
        
        let promise = Promise<Int>()
        
        promise
            .complete { .value(1) }
            .future
            .onSuccess { val in
                
                XCTAssertEqual(1, val)
                
                ex.fulfill()
            }
            .onFailure { _ in
                
                XCTFail("Must not reach.")
                
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testCompleteWith() {
        
        let ex = expectation(description: "Promise")
        
        let promise = Promise<Int>()
        
        promise
            .completeWith { Future(.value(1)) }
            .future
            .onSuccess { val in
                
                XCTAssertEqual(1, val)
                
                ex.fulfill()
            }
            .onFailure { _ in
                
                XCTFail("Must not reach.")
                
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
}
