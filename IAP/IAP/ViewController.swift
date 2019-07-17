//
//  ViewController.swift
//  IAP
//
//  Created by imac on 7/16/19.
//  Copyright © 2019 JeguLabs. All rights reserved.
//

import UIKit
import SwiftyStoreKit

private var sharedSecret = "cad7ea1b02724d7ebff55ec88f4f515f"

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    let inAppPurchasesIds = [
        ["com.JeguLabs.IAP.Subscription"]
    ]
    
    let purchaseBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Purchase subscription", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.backgroundColor = .white
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.black.cgColor
        btn.layer.cornerRadius = 25
        
        btn.addTarget(self, action: #selector(handleBtnPressed), for: .touchUpInside)
        
        return btn
    }()
    
    let restoreBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Restore", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        btn.backgroundColor = .white
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.red.cgColor
        btn.layer.cornerRadius = 25
        
        btn.addTarget(self, action: #selector(handleRestorePressed), for: .touchUpInside)
        
        return btn
    }()
    
    let subsTxtLb: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.textColor = .black
        lbl.text = "Item"
        return lbl
    }()
    
    
    // MARK: - Handlers
    
    @objc func handleBtnPressed() {
        purchaseSubscription(with: "com.JeguLabs.IAP.Subscription", sharedSecret: sharedSecret)
    }
    
    @objc func handleRestorePressed() {
        restorePurchases()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewComponents()
        setupStoreKitComponents()
        
    }
    
    // MARK: - Helper functions
    
    func setupViewComponents() {
        view.backgroundColor = .white
        
        view.addSubview(purchaseBtn)
        purchaseBtn.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 64)
        purchaseBtn.centerY(inView: view)
        
        view.addSubview(restoreBtn)
        restoreBtn.anchor(top: purchaseBtn.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 64)
        
        view.addSubview(subsTxtLb)
        subsTxtLb.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: purchaseBtn.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 50, paddingRight: 20, width: 0, height: 0)
    }
    
    // MARK: - SwiftyStore
    
    func setupStoreKitComponents() {
        
        SwiftyStoreKit.retrieveProductsInfo(["com.JeguLabs.IAP.Subscription"]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                self.subsTxtLb.text = ("Product: \(product.localizedDescription), price: \(priceString)")
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
            }
            else {
                print("Error: \(result.error ?? "Feelsbad" as! Error)")
            }
        }
        
        // Consumable - Non-Consumable
        
        // Subscription
        verifyPurchase(with: "com.JeguLabs.IAP.Subscription", sharedSecret: sharedSecret, type: .autoRenewable)

    }
    
    
    // MARK: - Real stuff
    
    
    // Consumable & Non-Consumable stuff
    func purchaseProduct(with id: String) {
        
        SwiftyStoreKit.retrieveProductsInfo([id]) { result in
            if let product = result.retrievedProducts.first {
                SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
                    switch result {
                    case .success(let product):
                        // fetch content from your server, then:
                        if product.needsFinishTransaction {
                            SwiftyStoreKit.finishTransaction(product.transaction)
                        }
                        print("Purchase Success: \(product.productId)")
                    case .error(let error):
                        switch error.code {
                        case .unknown: print("Unknown error. Please contact support")
                        case .clientInvalid: print("Not allowed to make the payment")
                        case .paymentCancelled: break
                        case .paymentInvalid: print("The purchase identifier was invalid")
                        case .paymentNotAllowed: print("The device is not allowed to make the payment")
                        case .storeProductNotAvailable: print("The product is not available in the current storefront")
                        case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                        case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                        case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                        default: print((error as NSError).localizedDescription)
                        }
                    }
                }
            }
        }
    }
    
    // Subscription
    func purchaseSubscription(with id: String, sharedSecret: String) {
        
        SwiftyStoreKit.purchaseProduct(id, atomically: true) { result in
            
            if case .success(let purchase) = result {
                // Deliver content from server, then:
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                
                let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: sharedSecret)
                SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
                    
                    if case .success(let receipt) = result {
                        let purchaseResult = SwiftyStoreKit.verifySubscription(
                            ofType: .autoRenewable,
                            productId: id,
                            inReceipt: receipt)
                        
                        switch purchaseResult {
                        case .purchased(let expiryDate):
                            print("Product is valid until \(expiryDate)")
                        case .expired(let expiryDate):
                            print("Product is expired since \(expiryDate)")
                        case .notPurchased:
                            print("This product has never been purchased")
                        }
                        
                    } else {
                        // receipt verification error
                    }
                }
            } else {
                // purchase error
            }
        }
    }
    
    
    func restorePurchases() {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoreFailedPurchases.count > 0 {
                print("Restore Failed: \(results.restoreFailedPurchases)")
            }
            else if results.restoredPurchases.count > 0 {
                print("Restore Success: \(results.restoredPurchases)")
            }
            else {
                print("Nothing to Restore")
            }
        }
    }

    
    
    enum PurchaseType: Int {
        case simple = 0,
        autoRenewable,
        nonRenewing
    }
    
    func verifyPurchase(with id: String, sharedSecret: String, type: PurchaseType, validDuration: TimeInterval? = nil) {
        
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                let productId = id
                // Verify the purchase of a Subscription
                
                switch type {
                case .simple:
                    let productId = id
                    // Verify the purchase of Consumable or NonConsumable
                    let purchaseResult = SwiftyStoreKit.verifyPurchase(
                        productId: productId,
                        inReceipt: receipt)
                    
                    switch purchaseResult {
                    case .purchased(let receiptItem):
                        print("\(productId) is purchased: \(receiptItem)")
                    case .notPurchased:
                        print("The user has never purchased \(productId)")
                    }
                case .autoRenewable:
                    let purchaseResult = SwiftyStoreKit.verifySubscription(
                        ofType: .autoRenewable, // or .nonRenewing (see below)
                        productId: productId,
                        inReceipt: receipt)
                    
                    switch purchaseResult {
                    case .purchased(let expiryDate, let items):
                        print("\(productId) is valid until \(expiryDate)\n\(items)\n")
                    case .expired(let expiryDate, let items):
                        print("\(productId) is expired since \(expiryDate)\n\(items)\n")
                    case .notPurchased:
                        print("The user has never purchased \(productId)")
                    }
                case .nonRenewing:
                    guard let validDuration = validDuration as TimeInterval? else { return }
                    let purchaseResult = SwiftyStoreKit.verifySubscription(
                        ofType: .nonRenewing(validDuration: validDuration),
                        productId: "com.musevisions.SwiftyStoreKit.Subscription",
                        inReceipt: receipt)
                    
                    switch purchaseResult {
                    case .purchased(let expiryDate, let items):
                        print("\(productId) is valid until \(expiryDate)\n\(items)\n")
                    case .expired(let expiryDate, let items):
                        print("\(productId) is expired since \(expiryDate)\n\(items)\n")
                    case .notPurchased:
                        print("The user has never purchased \(productId)")
                    }
                    
                }
            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
        }
        
    }

}

