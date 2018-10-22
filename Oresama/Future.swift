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
            
            if result != nil {
                
                fatalError("Result already seted.")
            }
        }
        
        didSet {
            
            guard let result = self.result else {
                
                fatalError("set nil to result.")
            }
            
            semaphore?.signal()
            
            callbacksLock.lock()
            defer { callbacksLock.unlock() }
            
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
            
            if case let .value(v) = result {
                
                callback(v)
            }
        }
        
        return self
    }
    
    @discardableResult
    func onFailure(_ callback: @escaping (Error) -> Void) -> Self {
        
        onComplete { result in
            
            if case let .error(e) = result {
                
                callback(e)
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
                
                switch self.await().value {
                    
                case .value(let v)?: return t(v)
                    
                case .error(let e)?: return Future<U>(e)
                    
                case nil: fatalError("Future not complete")
                    
                }
            }
            .future
    }
    
    func filter(_ f: @escaping (T) -> Bool) -> Future<T> {
        
        return Promise()
            .complete {
                
                if case let .value(v)? = self.await().value, f(v) {
                    
                    return .value(v)
                }
                
                return .error(FutureError.noSuchElement)
            }
            .future
    }
    
    func recover(_ s: @escaping (Error) throws -> T) -> Future<T> {
        
        return transform { result in
            
            do {
                
                switch result {
                    
                case .value: return result
                    
                case let .error(err): return .value(try s(err))
                }
                
            } catch {
                
                return .error(error)
            }
        }
    }
    
    @discardableResult
    func andThen(_ f: @escaping (Result<T>) -> Void) -> Future<T> {
        
        return Promise<T>()
            .complete {
                
                guard let result = self.await().result else {
                    
                    fatalError("Future not complete")
                }
                
                f(result)
                
                return result
            }
            .future
    }
}


// MARK: - Internal

internal extension Future {
    
    func complete(_ result: Result<T>) {
        
        self.result = result
    }
}
