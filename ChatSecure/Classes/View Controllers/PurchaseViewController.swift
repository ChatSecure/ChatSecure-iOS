//
//  PurchaseViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 5/5/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import StoreKit
import FormatterKit
import MBProgressHUD
import OTRAssets

public class PurchaseViewController: UIViewController {
    @IBOutlet weak var bigMoneyButton: UIButton!
    @IBOutlet weak var smallMoneyButton: UIButton!
    @IBOutlet weak var mediumMoneyButton: UIButton!
    fileprivate let maybeLaterSegue = "maybeLaterSegue"
    let observer = TransactionObserver.shared
    
    var allMoneyButtons: [UIButton:Product] {
        return [smallMoneyButton: .small, mediumMoneyButton: .medium, bigMoneyButton: .big]
    }
    
    enum Product: String {
        case small = "3_donation_monthly" // "3_donation_nonconsumable" // "3_donation_consumable"
        case medium = "6_donation_monthly" // "6_donation_consumable"
        case big = "20_donation_monthly" // "20_donation_consumable"
        static let allProductsSet = Set([small.rawValue, medium.rawValue, big.rawValue])
        var emoji: String {
            switch self {
            case .small:
                return "☕️"
            case .medium:
                return "🍺"
            case .big:
                return "🎁"
            }
        }
    }
    private var productsRequest: SKProductsRequest?
    var products: [Product:SKProduct] = [:]
    
    deinit {
        observer.transactionSuccess = nil
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        observer.transactionSuccess = { [weak self] (transaction) in
            guard let strongSelf = self else { return }
            strongSelf.progressToMaybeLater(sender: strongSelf)
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !SKPaymentQueue.canMakePayments() {
            allMoneyButtons.forEach {
                $0.key.isEnabled = false
            }
            let alert = UIAlertController(title: PAYMENTS_UNAVAILABLE_STRING(), message: nil, preferredStyle: .alert)
            let ok = UIAlertAction(title: OK_STRING(), style: .default, handler: { (action) in
                self.progressToMaybeLater(sender: self)
            })
            alert.addAction(ok)
            alert.show(self, sender: nil)
            NSLog("User cannot make payments.")
            // TODO: show user cant make payments
            return
        }
        refreshMoneyButtons()
        productsRequest?.cancel()
        let request = SKProductsRequest(productIdentifiers: Product.allProductsSet)
        request.delegate = self
        request.start()
        productsRequest = request
        MBProgressHUD.showAdded(to: self.view, animated: true)
    }
    
    fileprivate func refreshMoneyButtons() {
        allMoneyButtons.forEach { (button, productEnum) in
            guard let product = products[productEnum] else {
                button.isEnabled = false
                NSLog("Product not found")
                return
            }
            button.isEnabled = true
            let price = product.formattedPrice ?? product.price.stringValue
            let duration = NSLocalizedString("mo", tableName: "FormatterKit", bundle: Bundle.formatterKit(), value: "mo", comment: "Month")
            let fullPrice = "\(productEnum.emoji) \(price)/\(duration)"
            button.setTitle(fullPrice, for: .normal)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
        }
    }
    
    private func buy(product: SKProduct, sender: Any) {
        NSLog("Buying \"\(product.localizedTitle)\" (\(product.productIdentifier))...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    private func buyButtonPressed(_ sender: Any) {
        if let button = sender as? UIButton, let productEnum = allMoneyButtons[button], let product = products[productEnum] {
            buy(product: product, sender: sender)
        } else {
            NSLog("Could not buy product via button \(sender)")
        }
    }
    
    fileprivate func progressToMaybeLater(sender: Any) {
        self.performSegue(withIdentifier: maybeLaterSegue, sender: sender)
    }
    
    @IBAction func restoreButtonPressed(_ sender: Any) {
        NSLog("Restore button pressed")
        SKPaymentQueue.default().transactions.forEach {
            NSLog("transaction in queue: \($0)")
        }
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    @IBAction func smallMoneyButtonPressed(_ sender: Any) {
        buyButtonPressed(sender)
    }
    
    @IBAction func mediumMoneyButtonPressed(_ sender: Any) {
        buyButtonPressed(sender)

    }
    
    @IBAction func bigMoneyButtonPressed(_ sender: Any) {
        buyButtonPressed(sender)

    }
    
}

extension PurchaseViewController: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        response.products.forEach {
            guard let product = $0.product else {
                NSLog("Unrecognized product: \($0)")
                return
            }
            products[product] = $0
            NSLog("Product \"\($0.localizedTitle)\" (\($0.productIdentifier)):  \($0.price.floatValue)")
        }
        refreshMoneyButtons()
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        NSLog("Error loading products: \(error.localizedDescription)")
        MBProgressHUD.hide(for: self.view, animated: true)
    }
}

extension SKProduct {
    var product: PurchaseViewController.Product? {
        return PurchaseViewController.Product(rawValue: productIdentifier)
    }
    
    /** Returns the locale-aware price */
    var formattedPrice: String? {
        let nf = NumberFormatter()
        nf.formatterBehavior = .behavior10_4
        nf.numberStyle = .currency
        nf.locale = priceLocale
        return nf.string(from: price)
    }
}

public class TransactionObserver: NSObject, SKPaymentTransactionObserver {
    public static let shared = TransactionObserver()
    let paymentQueue = SKPaymentQueue.default()
    public var transactionSuccess: ((_ transaction: SKPaymentTransaction) -> Void)?
    
    deinit {
        stopObserving()
    }
    
    public static var receiptData: Data? {
        var data: Data? = nil
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        do {
            data = try Data(contentsOf: url)
        } catch {}
        return data
    }
    
    public static var hasValidReceipt: Bool {
        guard let receipt = receiptData else {
            return false
        }
        // We skip verification because we don't really care if the user has paid
        return receipt.count > 0
    }
    
    /** Start observing IAP transactions */
    public func startObserving() {
        paymentQueue.add(self)
    }
    
    public func stopObserving() {
        paymentQueue.remove(self)
    }
    
    // MARK: SKPaymentTransactionObserver
    
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
                NSLog("Transaction deferred: \(transaction)")
                break
            case .purchasing:
                NSLog("Transaction purchasing: \(transaction)")
                break
            }
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        NSLog("Payment queue restore finished")
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        NSLog("Payment queue restore failed with error \(error)")
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        NSLog("Transaction complete: \(transaction)")
        SKPaymentQueue.default().finishTransaction(transaction)
        transactionSuccess?(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let _ = transaction.original?.payment.productIdentifier else {
            NSLog("Cannot restore: No original transaction: \(transaction)")
            return
        }
        
        NSLog("Transaction restored: \(transaction)")
        SKPaymentQueue.default().finishTransaction(transaction)
        transactionSuccess?(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        NSLog("Transaction failed: \(transaction) \(String(describing: transaction.error))")
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}
