//
//  Debouncer.swift
//
//
//  Created by NGUYEN CHI CONG on 3/2/17.
//  Copyright © 2017 [iF] Solution Co., Ltd. All rights reserved.
//

import Foundation

class Debouncer: NSObject {
    private(set) var callback: (() -> ())
    private(set) var delay: Double
    private(set) weak var timer: Timer?
    
    init(delay: Double, callback: @escaping (() -> ())) {
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
    
    @objc func fireNow() {
        callback()
    }
}
