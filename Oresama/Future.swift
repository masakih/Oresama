//
//  Future.swift
//  Oresama
//
//  Created by Hori,Masaki on 2018/01/13.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

import Foundation


// MARK: - FutureError

public enum FutureError: Error {
    
    case unsolvedFuture
    
    case noSuchElement
}


// MARK: - Future<T>

public final class Future<T> {
    
    
    // MARK: - Public
    
    public var isCompleted: Bool {
        
        return result != nil
    }
    
    public var value: Result<T>? {
        
        return result
    }
    
    /// Life cycle
    public init() {
        
        // for await()
        semaphore = DispatchSemaphore(value: 0)
    }
    
    public init(in queue: DispatchQueue = .global(), _ block: @escaping () throws -> T) {
        
        // for await()
        semaphore = DispatchSemaphore(value: 0)
        
        queue.async {
            
            defer { self.semaphore?.signal() }
            
            do {
                
                self.result = .value(try block())
                
            } catch {
                
                self.result = .error(error)
            }
        }
    }
    
    public init(_ result: Result<T>) {
        
        semaphore = nil
        
        self.result = result
    }
    
    public convenience init(_ value: T) {
        
        self.init(.value(value))
    }
    
    public convenience init(_ error: Error) {
        
        self.init(.error(error))
    }
    
    deinit {
        
        semaphore?.signal()
    }
    
    
    // MARK: - Private
    
    private let semaphore: DispatchSemaphore?
    
    private var callbacks: [(Result<T>) -> Void] = []
    private let callbacksLock = NSLock()
    
    private var result: Result<T>? {
        
        willSet {
            
            callbacksLock.lock()
            
            if result != nil {
                
                fatalError("Result already seted.")
            }
        }
        
        didSet {
            
            defer { callbacksLock.unlock() }
            
            guard let result = self.result else {
                
                fatalError("set nil to result.")
            }
            
            semaphore?.signal()
            
            callbacks.forEach { f in f(result) }
            callbacks = []
        }
    }
}


// MARK: - Public

public extension Future {
    
    
    @discardableResult
    func await() -> Self {
        
        if result == nil {
            
            semaphore?.wait()
            semaphore?.signal()
        }
        
        return self
    }
    
    @discardableResult
    func onComplete(_ callback: @escaping (Result<T>) -> Void) -> Self {
        
        if let r = result {
            
            callback(r)
            
        } else {
            
            callbacksLock.lock()
            defer { callbacksLock.unlock() }
            
            callbacks.append(callback)
        }
        
        return self
    }
    
    @discardableResult
    func onSuccess(_ callback: @escaping (T) -> Void) -> Self {
        
        onComplete { result in
            
            if case let .value(value) = result {
                
                callback(value)
            }
        }
        
        return self
    }
    
    @discardableResult
    func onFailure(_ callback: @escaping (Error) -> Void) -> Self {
        
        onComplete { result in
            
            if case let .error(error) = result {
                
                callback(error)
            }
        }
        
        return self
    }
}

public extension Future {
    
    ///
    func transform<U>(_ s: @escaping (T) -> U, _ f: @escaping (Error) -> Error) -> Future<U> {
        
        return transform { result in
            
            switch result {
                
            case let .value(value): return .value(s(value))
                
            case let .error(error): return .error(f(error))
                
            }
        }
    }
    
    func transform<U>(_ s: @escaping (Result<T>) -> Result<U>) ->Future<U> {
        
        return Promise()
            .complete { s(self.await().result!) }
            .future
    }
    
    func map<U>(_ t: @escaping (T) -> U) -> Future<U> {
        
        return transform(t, { $0 })
    }
    
    func flatMap<U>(_ t: @escaping (T) -> Future<U>) -> Future<U> {
        
        return Promise()
            .completeWith {
                
                switch self.await().value! {
                    
                case let .value(value): return t(value)
                    
                case let .error(error): return Future<U>(error)
                }
            }
            .future
    }
    
    func filter(_ f: @escaping (T) -> Bool) -> Future {
        
        return Promise()
            .complete {
                
                if case let .value(value) = self.await().value!, f(value) {
                    
                    return .value(value)
                }
                
                return .error(FutureError.noSuchElement)
            }
            .future
    }
    
    func recover(_ s: @escaping (Error) throws -> T) -> Future {
        
        return transform { result in
            
            do {
                
                switch result {
                    
                case .value: return result
                    
                case let .error(error): return .value(try s(error))
                }
                
            } catch {
                
                return .error(error)
            }
        }
    }
    
    func recoverWith(_ s: @escaping (Error) -> Future) -> Future {
        
        switch self.await().value! {
            
        case .value: return self
            
        case let .error(error): return s(error)
        }
    }
    
    @discardableResult
    func andThen(_ f: @escaping (Result<T>) -> Void) -> Future {
        
        return Promise()
            .complete {
                
                let result = self.await().result!
                
                f(result)
                
                return result
            }
            .future
    }
}

extension Future: Equatable where T: Equatable {
    
    public static func == (lhs: Future, rhs: Future) -> Bool {
        
        switch (lhs.await().value!, rhs.await().value!) {
            
        case let (.value(lval), .value(rval)): return lval == rval
            
        case let (.error(lerr as NSError), .error(rerr as NSError)): return lerr == rerr
            
        default: return false
            
        }
    }
}


// MARK: - Internal

internal extension Future {
    
    func complete(_ result: Result<T>) {
        
        self.result = result
    }
}
