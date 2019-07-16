//
//  ViewController.swift
//  IAP
//
//  Created by imac on 7/16/19.
//  Copyright © 2019 JeguLabs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
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
    
    
    // MARK: - Handlers
    
    @objc func handleBtnPressed() {
        print("Handle btn")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewComponents()
        
    }
    
    func setupViewComponents() {
        view.backgroundColor = .white
        
        view.addSubview(purchaseBtn)
        purchaseBtn.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 64)
        purchaseBtn.centerY(inView: view)
    }


}

