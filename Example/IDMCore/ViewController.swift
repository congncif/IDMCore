//
//  ViewController.swift
//  IDMCore
//
//  Created by Nguyen Chi Cong on 08/16/2016.
//  Copyright (c) 2016 Nguyen Chi Cong. All rights reserved.
//

import UIKit
import IDMCore

class DataProvider1: DataProviderProtocol {
    
    func request(parameters: String?, completion: ((Bool, String?, Error?) -> ())?) -> (() -> ())? {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(3)) {
            completion?(true, "result 1", nil)
        }

        return {}
    }
}

class DataProvider2: DataProviderProtocol {
    func request(parameters: Int?, completion: ((Bool, String?, Error?) -> ())?) -> (() -> ())? {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
            completion?(true, "result 2", nil)
        }
        
        return {}
    }
}

class ViewController: UIViewController {

    let integrator = AmazingIntegrator(dataProvider: DataProvider2() >>>> DataProvider1())
    
    let integrator2 = AmazingIntegrator(dataProvider: DataProvider1() >><< DataProvider2())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        integrator.prepareCall().onSuccess { (result) in
            print(result?.data)
            }.call()
        
        integrator2.prepareCall().onSuccess { (results) in
            print(results)
        }.call()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

