//
//  Result.swift
//  Oresama
//
//  Created by Hori,Masaki on 2018/10/22.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Foundation


// MARK: - Result<T>


public enum Result<T> {
    
    case value(T)
    
    case error(Error)
    
    init(_ value: T) {
        
        self = .value(value)
    }
    
    init(_ error: Error) {
        
        self = .error(error)
    }
}


public extension Result {
    
    var value: T? {
        
        if case let .value(value) = self { return value }
        
        return nil
    }
    
    var error: Error? {
        
        if case let .error(error) = self { return error }
        
        return nil
    }
}


public extension Result {
    
    func map<U>(_ f: (T) -> U) -> Result<U> {
        
        switch self {
            
        case let .value(val): return .value(f(val))
            
        case let .error(err): return .error(err)
        }
    }
    
    func flatMap<U>(_ f: (T) -> Result<U>) -> Result<U> {
        
        switch self {
            
        case let .value(val): return f(val)
            
        case let .error(err): return .error(err)
        }
    }
}


public extension Result {
    
    @discardableResult
    func ifSuccess(_ f: (T) -> Void) -> Result {
        
        switch self {
            
        case let .value(val): f(val)
            
        case .error: ()
        }
        
        return self
    }
    
    @discardableResult
    func ifFailure(_ f: (Error) -> Void) -> Result {
        
        switch self {
            
        case .value: ()
            
        case let .error(err): f(err)
        }
        
        return self
    }
}