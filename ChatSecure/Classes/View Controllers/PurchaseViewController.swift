//
//  PurchaseViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 5/5/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import StoreKit

public class PurchaseViewController: UIViewController {
    @IBOutlet weak var bigMoneyButton: UIButton!
    @IBOutlet weak var smallMoneyButton: UIButton!
    @IBOutlet weak var mediumMoneyButton: UIButton!
    
    
    
    var productIdentifiers: Set<String> = Set([""]) // TODO: replace w/ dynamic products fetch
    var productsRequest: SKProductsRequest?
    var products: [SKProduct] = []

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !SKPaymentQueue.canMakePayments() {
            // TODO: show user cant make payments
            return
        }

        productsRequest?.cancel()
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
        productsRequest = request
    }
    
    public func buy(product: SKProduct, sender: Any) {
        NSLog("Buying \"\(product.localizedTitle)\" (\(product.productIdentifier))...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    
    @IBAction func restoreButtonPressed(_ sender: Any) {
    }
    
    @IBAction func smallMoneyButtonPressed(_ sender: Any) {
    }
    
    @IBAction func mediumMoneyButtonPressed(_ sender: Any) {
    }
    
    @IBAction func bigMoneyButtonPressed(_ sender: Any) {
        
    }
    
}

extension PurchaseViewController: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        for product in products {
            NSLog("Product \"\(product.localizedTitle)\" (\(product.productIdentifier)):  \(product.price.floatValue)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        NSLog("Error loading products: \(error.localizedDescription)")
    }
}

extension PurchaseViewController: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        NSLog("Transaction complete: \(transaction)")
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let _ = transaction.original?.payment.productIdentifier else { return }
        
        NSLog("Transaction restored: \(transaction)")
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        NSLog("Transaction failed: \(transaction) \(String(describing: transaction.error))")
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}
