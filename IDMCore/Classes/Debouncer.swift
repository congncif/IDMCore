//
//  Debouncer.swift
//
//
//  Created by NGUYEN CHI CONG on 3/2/17.
//  Copyright © 2017 [iF] Solution Co., Ltd. All rights reserved.
//

import Foundation

/* Using DispatchDebouncer instead
 
class Debouncer: NSObject {
    private(set) var callback: () -> ()
    private(set) var delay: TimeInterval
    private(set) weak var timer: Timer?

    init(delay: TimeInterval, callback: @escaping (() -> ())) {
        self.delay = delay
        self.callback = callback
    }

    deinit {
        cancel()
    }

    func call() {
        cancel()
        let nextTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(Debouncer.fireNow), userInfo: nil, repeats: false)
        timer = nextTimer
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func fireNow() {
        callback()
    }
}
*/

public class DispatchDebouncer {
    public let queue: DispatchQueue
    public let leeway: DispatchTimeInterval

    private(set) var timer: DispatchSourceTimer?

    public init(queue: DispatchQueue, leeway: DispatchTimeInterval = .nanoseconds(0)) {
        self.queue = queue
        self.leeway = leeway
    }

    private func dispatchInterval(_ interval: Foundation.TimeInterval) -> DispatchTimeInterval {
        precondition(interval >= 0)
        return DispatchTimeInterval.milliseconds(Int(interval * 1000))
    }

    deinit {
        cancel()
    }

    public func call(delay: TimeInterval, execute: @escaping (() -> ())) {
        cancel()

        let deadline = DispatchTime.now() + dispatchInterval(delay)

        let nextTimer = DispatchSource.makeTimerSource(queue: queue)
        nextTimer.schedule(deadline: deadline, leeway: leeway)

        timer = nextTimer

        timer?.setEventHandler(handler: execute)
        timer?.resume()
    }

    public func cancel() {
        timer?.cancel()
        timer = nil
    }
}
