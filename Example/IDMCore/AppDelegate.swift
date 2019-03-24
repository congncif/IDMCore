//
//  AppDelegate.swift
//  IDMCore
//
//  Created by Nguyen Chi Cong on 08/16/2016.
//  Copyright (c) 2016 Nguyen Chi Cong. All rights reserved.
//

import UIKit
import IDMCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let vc = ViewController()
        let handler = DedicatedErrorHandler(errorType: XXX.self, viewController: vc)
        handler.handle(error: XXX(message: "DCMVCL"))
        
        return true
    }
}

struct XXX: XXXError {
    var message: String
    
}

protocol XXXError: Error {
    var message: String { get }
}

extension DedicatedErrorHandler where E: XXXError {
    init(errorType: E.Type, viewController: UIViewController?) {
        self.init(errorType: errorType) { [weak viewController] error in
            print("XXX handled: \(error.message) by \(viewController)")
        }
    }
}
