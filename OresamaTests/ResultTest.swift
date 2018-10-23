//
//  ResultTest.swift
//  OresamaTests
//
//  Created by Hori,Masaki on 2018/10/22.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import XCTest

@testable import Oresama


class ResultTest: XCTestCase {
    
    let testError = NSError(domain: "ResultTest", code: -100, userInfo: nil)

    func testCreateSuccess() {
        
        let result = Result<Int>(1)
        
        guard let val = result.value else {
            
            XCTFail()
            return
        }
        
        XCTAssertEqual(1, val)
    }
    
    func testCreateFailure() {
        
        let result = Result<Int>(testError)
        
        guard let err = (result.error as NSError?) else {
            
            XCTFail()
            return
        }
        
        XCTAssertEqual(testError, err)
    }
    
    func testMapSuccess() {
        
        let result = Result<Int>(1)
        
        let new = result.map { val in String(val) }
        
        guard let val = new.value else {
            
            XCTFail()
            return
        }
        
        XCTAssertEqual("1", val)
    }
    
    func testMapError() {
        
        let result = Result<Int>(testError)
        
        let new = result.map { val in String(val) }
        
        guard let err = (new.error as NSError?) else {
            
            XCTFail()
            return
        }
        
        XCTAssertEqual(testError, err)
    }
    
    func testFlatMapSuccess2Success() {
        
        let result = Result<Int>(1)
        
        let new = result.flatMap { val in .value(String(val)) }
        
        guard let val = new.value else {
            
            XCTFail()
            return
        }
        
        XCTAssertEqual("1", val)
    }
    
    func testFlatMapSuccess2Error() {
        
        let result = Result<Int>(1)
        
        let new: Result<String> = result.flatMap { _ in .error(testError) }
        
        guard let err = (new.error as NSError?) else {
            
            XCTFail()
            return
        }
        
        XCTAssertEqual(testError, err)
    }
    
    func testFlatMapError() {
        
        let result = Result<Int>(testError)
        
        let new = result.flatMap { val in .value(String(val)) }
        
        guard let err = (new.error as NSError?) else {
            
            XCTFail()
            return
        }
        
        XCTAssertEqual(testError, err)
    }
    
    func testIfSuccess() {
        
        let ex = expectation(description: "Result")
        
        let result = Result<Int>(1)
        
        result
            .ifSuccess { val in
                
                XCTAssertEqual(1, val)
                
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 0)
        
    }
    
    func testIfFailure() {
        
        let ex = expectation(description: "Result")
        
        let result = Result<Int>(testError)
        
        result
            .ifFailure { err in
                
                XCTAssertEqual(testError, err as NSError)
                
                ex.fulfill()
        }
        
        waitForExpectations(timeout: 0)
    }
    
    func testEquatable() {
        
        let result1 = Result(1)
        let result2 = Result(1)
        let result3 = Result(2)
        let result4 = Result<Int>(NSError(domain: "hoge", code: 0, userInfo: nil))
        let result5 = Result<Int>(NSError(domain: "hoge", code: 0, userInfo: nil))
        let result6 = Result<Int>(NSError(domain: "hoge", code: 1, userInfo: nil))
        
        XCTAssertEqual(result1, result2)
        XCTAssertNotEqual(result1, result3)
        
        XCTAssertEqual(result4, result5)
        XCTAssertNotEqual(result4, result6)
        
        XCTAssertNotEqual(result1, result4)
    }
    
    func testFunctor() {
        
        func i<T>(_ x: T) -> T { return x }
        
        let result = Result(1)
        
        XCTAssertEqual(result.map(i), i(result))
        
        ///
        
        func f(_ j: Int) -> String {
            
            return String(j)
        }
        func g(_ s: String) -> Double {
            
            return Double(s)!
        }
        
        XCTAssertEqual(result.map( { g(f($0)) } ),
                       result.map(f).map(g))
    }
    
    func testMonad() {
        
        let value = 1
        
        func f(_ i: Int) -> Result<String> {
            
            return Result(String(i))
        }
        
        XCTAssertEqual(Result(value).flatMap(f),
                        f(value))
        
        ///
        let result = Result(2)
        
        XCTAssertEqual(result.flatMap( { Result($0) } ),
                       result)
        
        ///
        func g(_ s: String) -> Result<Double> {
            
            return Result(Double(s)!)
        }
        
        XCTAssertEqual(result.flatMap( { f($0).flatMap(g) } ),
                       result.flatMap(f).flatMap(g))
    }
}
