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
        print("Handle btn")
    }
    
    @objc func handleRestorePressed() {
        print("Restore")
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
//        verifyPurchase(with: "com.JeguLabs.IAP.Subscription", sharedSecret: sharedSecret)
        
        // Subscription
        verifySubscription(with: "com.JeguLabs.IAP.Subscription", sharedSecret: sharedSecret, type: .autoRenewable)
        
    }
    
    func verifyPurchase(with id: String, sharedSecret: String) {
        
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
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
            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
        }
        
    }
    
    enum SubsType: Int {
        case autoRenewable = 0,
        nonRenewing
    }
    
    func verifySubscription(with id: String, sharedSecret: String, type: SubsType, validDuration: TimeInterval? = nil) {
        
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                let productId = id
                // Verify the purchase of a Subscription
                
                switch type {
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

