//
//  Promise.swift
//  Oresama
//
//  Created by Hori,Masaki on 2018/10/22.
//  Copyright © 2018 Hori,Masaki. All rights reserved.
//

import Foundation


// MARK: - Private

private let promiseQueue = DispatchQueue(label: "Promise", attributes: .concurrent)


// MARK: - Promise<T>

public final class Promise<T> {
    
    
    // MARK: - Public
    
    public let future = Future<T>()
    
    public init() {}
    
    ///
    public func complete(_ result: Result<T>) {
        
        future.complete(result)
    }
    
    public func success(_ value: T) {
        
        complete(.value(value))
    }
    
    public func failure(_ error: Error) {
        
        complete(.error(error))
    }
    
    @discardableResult
    public func complete(_ completor: @escaping () -> Result<T>) -> Self {
        
        promiseQueue.async {
            
            self.complete(completor())
        }
        
        return self
    }
    
    @discardableResult
    public func completeWith(_ completor: @escaping () -> Future<T>) -> Self {
        
        promiseQueue.async {
            
            completor()
                .onSuccess {
                    
                    self.success($0)
                    
                }
                .onFailure {
                    
                    self.failure($0)
                    
            }
        }
        
        return self
    }
}
