//
//  AppDelegate.swift
//  CloudKitchenSink
//
//  Created by Guilherme Rambo on 05/03/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import UIKit
import CloudKit

extension UIViewController {
    
    var container: CKContainer {
        return CKContainer(identifier: "iCloud.br.com.guilhermerambo.KitchenContainer")
    }
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        configureCloudKit()
        
        return true
    }
    
    private func configureCloudKit() {
        let container = CKContainer(identifier: "iCloud.br.com.guilhermerambo.KitchenContainer")
        
        container.privateCloudDatabase.fetchAllRecordZones { zones, error in
            guard let zones = zones, error == nil else {
                // error handling magic
                return
            }
            
            print("I have these zones: \(zones)")
        }
    }


}

