//
//  AtomicBool.swift
//  IDMCore
//
//  Created by FOLY on 12/10/18.
//

import Foundation

public class AtomicBool {
    fileprivate var queue = DispatchQueue.idmRunQueue

    public init(queue: DispatchQueue = DispatchQueue.idmRunQueue) {
        self.queue = queue
    }

    private var _value: Bool = false
    public var value: Bool {
        get {
            var result: Bool = false
            queue.sync {
                result = _value
            }
            return result
        }
        set {
            queue.async(flags: .barrier) {
                self._value = newValue
            }
        }
    }
}
