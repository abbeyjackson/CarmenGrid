//
//  AppDelegate.swift
//  Carmen Grid
//
//  Created by Abbey Jackson on 2019-03-26.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import UIKit
import Instabug

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if !(self.isRunningLive()) {
            Instabug.start(withToken: "1d22a52ccaebee231b1a8282e23d795a", invocationEvent: .shake)
            Instabug.setReproStepsMode(.enable)
            Instabug.setUserStepsEnabled(true)
        }
        return true
    }
    
    func isRunningLive() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let isRunningTestFlightBeta  = (Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt")
        let hasEmbeddedMobileProvision = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil
        if (isRunningTestFlightBeta || hasEmbeddedMobileProvision) {
            return false
        } else {
            return true
        }
        #endif
    }
}

