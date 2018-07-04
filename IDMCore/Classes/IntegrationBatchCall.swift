/**
 Copyright (c) 2016 Nguyen Chi Cong
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

//
//  IntegrationBatchCall.swift
//  IDMFoundation
//
//  Created by FOLY on 3/13/18.
//

/**
 * IMPORTANT NOTE: Sequence IntegrationCall and IntegrationBatchCall only work perfectly if they are created from different Intergrators.
 */

import Foundation

public class GroupIntegrationCall<R1, R2> {
    var call1: IntegrationCall<R1>
    var call2: IntegrationCall<R2>
    
    init(_ call1: IntegrationCall<R1>, _ call2: IntegrationCall<R2>) {
        if let checked = call1.integrator?.isEqual(call2.integrator), checked {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        self.call1 = call1
        self.call2 = call2
    }
    
    public func call(queue: DispatchQueue = DispatchQueue.global(), delay: Double = 0, completion: (((Result<R1>, Result<R2>)) -> Void)? = nil) {
        IntegrationBatchCall().call(self, queue: queue, delay: delay, completion: completion)
    }
}

public class Group3IntegrationCall<R1, R2, R3> {
    var call1: IntegrationCall<R1>
    var call2: IntegrationCall<R2>
    var call3: IntegrationCall<R3>
    
    init(_ call1: IntegrationCall<R1>, _ call2: IntegrationCall<R2>, _ call3: IntegrationCall<R3>) {
        if call1.isSameIntegrator(with: call2) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call1.isSameIntegrator(with: call3) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call2.isSameIntegrator(with: call3) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        self.call1 = call1
        self.call2 = call2
        self.call3 = call3
    }
    
    public func call(queue: DispatchQueue = DispatchQueue.global(), delay: Double = 0, completion: (((Result<R1>, Result<R2>, Result<R3>)) -> Void)? = nil) {
        IntegrationBatchCall().call(self, queue: queue, delay: delay, completion: completion)
    }
}

public class Group4IntegrationCall<R1, R2, R3, R4> {
    var call1: IntegrationCall<R1>
    var call2: IntegrationCall<R2>
    var call3: IntegrationCall<R3>
    var call4: IntegrationCall<R4>
    
    init(_ call1: IntegrationCall<R1>, _ call2: IntegrationCall<R2>, _ call3: IntegrationCall<R3>, _ call4: IntegrationCall<R4>) {
        if call1.isSameIntegrator(with: call2) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call1.isSameIntegrator(with: call3) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call1.isSameIntegrator(with: call4) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call2.isSameIntegrator(with: call3) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call2.isSameIntegrator(with: call4) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call3.isSameIntegrator(with: call4) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        self.call1 = call1
        self.call2 = call2
        self.call3 = call3
        self.call4 = call4
    }
    
    public func call(queue: DispatchQueue = DispatchQueue.global(), delay: Double = 0, completion: (((Result<R1>, Result<R2>, Result<R3>, Result<R4>)) -> Void)? = nil) {
        IntegrationBatchCall().call(self, queue: queue, delay: delay, completion: completion)
    }
}

public class Group5IntegrationCall<R1, R2, R3, R4, R5> {
    var call1: IntegrationCall<R1>
    var call2: IntegrationCall<R2>
    var call3: IntegrationCall<R3>
    var call4: IntegrationCall<R4>
    var call5: IntegrationCall<R5>
    
    init(_ call1: IntegrationCall<R1>, _ call2: IntegrationCall<R2>, _ call3: IntegrationCall<R3>, _ call4: IntegrationCall<R4>, _ call5: IntegrationCall<R5>) {
        if call1.isSameIntegrator(with: call2) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call1.isSameIntegrator(with: call3) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call1.isSameIntegrator(with: call4) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call1.isSameIntegrator(with: call5) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call2.isSameIntegrator(with: call3) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call2.isSameIntegrator(with: call4) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call2.isSameIntegrator(with: call5) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call3.isSameIntegrator(with: call4) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call3.isSameIntegrator(with: call5) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        if call4.isSameIntegrator(with: call5) {
            fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
        }
        self.call1 = call1
        self.call2 = call2
        self.call3 = call3
        self.call4 = call4
        self.call5 = call5
    }
    
    public func call(queue: DispatchQueue = DispatchQueue.global(), delay: Double = 0, completion: (((Result<R1>, Result<R2>, Result<R3>, Result<R4>, Result<R5>)) -> Void)? = nil) {
        IntegrationBatchCall().call(self, queue: queue, delay: delay, completion: completion)
    }
}

public class IntegrationBatchCall {
    public init() {
//        #if DEBUG
//            print("Created a batch call")
//        #endif
    }
    
    public func call<M>(_ calls: [IntegrationCall<M>], queue: DispatchQueue = DispatchQueue.global(), delay: Double = 0, completion: (([Result<M>]) -> Void)? = nil) {
        let internalCalls = calls
        
        for (index, call) in internalCalls.enumerated() where index + 1 < internalCalls.count {
            for i in index + 1..<internalCalls.count {
                let other = internalCalls[i]
                if let checked = call.integrator?.isEqual(other.integrator), checked {
                    fatalError("IntegrationBatchCall only work perfectly if all of calls are created from different Intergrators")
                }
            }
        }
        
        let group = DispatchGroup()
        var results: [Result<M>] = []
        
        for call in internalCalls {
            group.enter()
            call
                .next(state: .success, nextBlock: { result in
                    if let data = result {
                        results.append(data)
                    }
                })
                .next(state: .error, nextBlock: { error in
                    if let data = error {
                        results.append(data)
                    }
                })
                .next(state: .completion, nextBlock: { _ in
                    group.leave()
                })
                .call(queue: queue, delay: delay)
        }
        
        group.notify(queue: queue) {
            completion?(results)
        }
    }
    
    public func call<R1, R2>(_ calls: GroupIntegrationCall<R1, R2>,
                             queue: DispatchQueue = DispatchQueue.global(),
                             delay: Double = 0,
                             completion: (((Result<R1>, Result<R2>)) -> Void)? = nil) {
        let group = DispatchGroup()
        
        var results: (Result<R1>, Result<R2>) = (.success(nil), .success(nil))
        
        group.enter()
        group.enter()
        
        calls.call1
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.0 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.0 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        calls.call2
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.1 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.1 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        group.notify(queue: queue) {
            completion?(results)
        }
    }
    
    public func call<R1, R2, R3>(_ calls: Group3IntegrationCall<R1, R2, R3>,
                                 queue: DispatchQueue = DispatchQueue.global(),
                                 delay: Double = 0,
                                 completion: (((Result<R1>, Result<R2>, Result<R3>)) -> Void)? = nil) {
        let group = DispatchGroup()
        
        var results: (Result<R1>, Result<R2>, Result<R3>) = (.success(nil), .success(nil), .success(nil))
        
        group.enter()
        group.enter()
        group.enter()
        
        calls.call1
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.0 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.0 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        calls.call2
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.1 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.1 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        calls.call3
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.2 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.2 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        group.notify(queue: queue) {
            completion?(results)
        }
    }
    
    public func call<R1, R2, R3, R4>(_ calls: Group4IntegrationCall<R1, R2, R3, R4>,
                                     queue: DispatchQueue = DispatchQueue.global(),
                                     delay: Double = 0,
                                     completion: (((Result<R1>, Result<R2>, Result<R3>, Result<R4>)) -> Void)? = nil) {
        let group = DispatchGroup()
        
        var results: (Result<R1>, Result<R2>, Result<R3>, Result<R4>) = (.success(nil), .success(nil), .success(nil), .success(nil))
        
        group.enter()
        group.enter()
        group.enter()
        group.enter()
        
        calls.call1
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.0 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.0 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        calls.call2
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.1 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.1 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        calls.call3
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.2 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.2 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        calls.call4
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.3 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.3 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        group.notify(queue: queue) {
            completion?(results)
        }
    }
    
    public func call<R1, R2, R3, R4, R5>(_ calls: Group5IntegrationCall<R1, R2, R3, R4, R5>,
                                         queue: DispatchQueue = DispatchQueue.global(),
                                         delay: Double = 0,
                                         completion: (((Result<R1>, Result<R2>, Result<R3>, Result<R4>, Result<R5>)) -> Void)? = nil) {
        let group = DispatchGroup()
        
        var results: (Result<R1>, Result<R2>, Result<R3>, Result<R4>, Result<R5>) = (.success(nil), .success(nil), .success(nil), .success(nil), .success(nil))
        
        group.enter()
        group.enter()
        group.enter()
        group.enter()
        group.enter()
        
        calls.call1
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.0 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.0 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        calls.call2
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.1 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.1 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        calls.call3
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.2 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.2 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        calls.call4
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.3 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.3 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        calls.call5
            .next(state: .success, nextBlock: { result in
                if let data = result {
                    results.4 = data
                }
            })
            .next(state: .error, nextBlock: { error in
                if let data = error {
                    results.4 = data
                }
            })
            .next(state: .completion, nextBlock: { _ in
                group.leave()
            })
            .call(queue: queue, delay: delay)
        
        group.notify(queue: queue) {
            completion?(results)
        }
    }
    
    public class func call<M>(_ calls: [IntegrationCall<M>], queue: DispatchQueue = DispatchQueue.global(), delay: Double = 0, completion: (([Result<M>]) -> Void)? = nil) {
        IntegrationBatchCall().call(calls, queue: queue, delay: delay, completion: completion)
    }
    
    deinit {
//        #if DEBUG
//            print("Batch call is released")
//        #endif
    }
}

extension Array {
    public func call<M>(queue: DispatchQueue = DispatchQueue.global(), delay: Double = 0, completion: (([Result<M>]) -> Void)? = nil) where Element == IntegrationCall<M> {
        IntegrationBatchCall.call(self, queue: queue, delay: delay, completion: completion)
    }
}

infix operator >-<: AdditionPrecedence

public func >-< <R1, R2>(left: IntegrationCall<R1>, right: IntegrationCall<R2>) -> GroupIntegrationCall<R1, R2> {
    return GroupIntegrationCall(left, right)
}

public func >-< <R1, R2, R3>(left: GroupIntegrationCall<R1, R2>, right: IntegrationCall<R3>) -> Group3IntegrationCall<R1, R2, R3> {
    return Group3IntegrationCall(left.call1, left.call2, right)
}

public func >-< <R1, R2, R3, R4>(left: Group3IntegrationCall<R1, R2, R3>, right: IntegrationCall<R4>) -> Group4IntegrationCall<R1, R2, R3, R4> {
    return Group4IntegrationCall(left.call1, left.call2, left.call3, right)
}

public func >-< <R1, R2, R3, R4, R5>(left: Group4IntegrationCall<R1, R2, R3, R4>, right: IntegrationCall<R5>) -> Group5IntegrationCall<R1, R2, R3, R4, R5> {
    return Group5IntegrationCall(left.call1, left.call2, left.call3, left.call4, right)
}
