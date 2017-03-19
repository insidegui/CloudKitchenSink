//
//  SubscriptionViewController.swift
//  CloudKitchenSink
//
//  Created by Guilherme Rambo on 19/03/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications

class SubscriptionViewController: UIViewController {

    @IBOutlet weak var subscribeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        checkSubscriptionStatus()
    }
    
    fileprivate var isSubscribed = false {
        didSet {
            subscribeButton.setTitle(isSubscribed ? "Cancel Subscription" : "Subscribe", for: .normal)
        }
    }
    
    fileprivate var subscriptionID: String? {
        get {
            return UserDefaults.standard.object(forKey: "subscriptionID") as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "subscriptionID")
        }
    }
    
    fileprivate func checkSubscriptionStatus() {
        isSubscribed = subscriptionID != nil
    }
    
    fileprivate func createSubscription() {
        subscribeButton.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { authorized, error in
            DispatchQueue.main.async {
                guard error == nil, authorized else {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    let alert = UIAlertController(title: "Not Authorized", message: "We need permission to show you notifications", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    return
                }
                
                self.saveSubscription()
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    fileprivate func saveSubscription() {
        let subscription = CKQuerySubscription(recordType: "Movie",
                                               predicate: NSPredicate(value: true),
                                               options: [.firesOnRecordCreation])
        
        let info = CKNotificationInfo()
        info.alertLocalizationKey = "movie_registered_alert"
        info.alertLocalizationArgs = ["title"]
        info.soundName = "default"
        info.desiredKeys = ["title"]
        subscription.notificationInfo = info
        
        container.publicCloudDatabase.save(subscription) { [weak self] savedSubscription, error in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.subscribeButton?.isEnabled = true
                
                guard let savedSubscription = savedSubscription, error == nil else { return }
                
                self?.isSubscribed = true
                
                UserDefaults.standard.set(savedSubscription.subscriptionID, forKey: "subscriptionID")
            }
        }
    }
    
    fileprivate func cancelSubscription() {
        guard let subscriptionID = subscriptionID else { return }
        
        subscribeButton.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: [subscriptionID])
        
        operation.modifySubscriptionsCompletionBlock = { [weak self] _, _, error in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.subscribeButton?.isEnabled = true
                
                guard error == nil else { return }
                
                self?.subscriptionID = nil
                self?.isSubscribed = false
            }
        }
        
        container.publicCloudDatabase.add(operation)
    }
    
    @IBAction func subscribe(_ sender: Any) {
        if isSubscribed {
            cancelSubscription()
        } else {
            createSubscription()
        }
    }

}
