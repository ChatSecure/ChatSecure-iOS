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
import Kvitto

extension PurchaseViewController {
    @objc public class func show(from viewController: UIViewController) {
        let assets = OTRAssets.resourcesBundle
        let storyboard = UIStoryboard(name: "Purchase", bundle: assets)
        guard let vc = storyboard.instantiateInitialViewController() else { return }
        vc.modalPresentationStyle = .formSheet
        let nav = UINavigationController(rootViewController: vc)
        nav.isNavigationBarHidden = true
        viewController.present(nav, animated: true, completion: nil)
    }
}

extension Bundle {
    static var formatterKit: Bundle? {
        let framework = Bundle(for: TTTUnitOfInformationFormatter.self)
        guard let path = framework.path(forResource: "FormatterKit", ofType: "bundle") else {
            return nil
        }
        let bundle = Bundle(path: path)
        return bundle
    }
}

public class PurchaseViewController: UIViewController {
    @IBOutlet weak var bigMoneyButton: UIButton!
    @IBOutlet weak var smallMoneyButton: UIButton!
    @IBOutlet weak var mediumMoneyButton: UIButton!
    fileprivate let maybeLaterSegue = "maybeLaterSegue"
    let observer = TransactionObserver.shared
    
    var allMoneyButtons: [UIButton:Product] {
        return [smallMoneyButton: .small, mediumMoneyButton: .medium, bigMoneyButton: .big]
    }
    
    enum Product: String, CaseIterable {
        #if targetEnvironment(macCatalyst)
        case small = "3_donation_monthly_mac"
        case medium = "6_donation_monthly_mac"
        case big = "20_donation_monthly_mac"
        #else
        case small = "3_donation_monthly"
        case medium = "6_donation_monthly"
        case big = "20_donation_monthly"
        #endif

        static var allProductsSet: Set<String> { Set(allCases.map { $0.rawValue }) }
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
            DDLogError("User cannot make payments.")
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
                DDLogError("Product not found for \(productEnum)")
                return
            }
            button.isEnabled = true
            let price = product.formattedPrice ?? product.price.stringValue
            var duration = "mo"
            if let bundle = Bundle.formatterKit {
                duration = NSLocalizedString("mo", tableName: "FormatterKit", bundle: bundle, value: "mo", comment: "Month")
            }
            let fullPrice = "\(productEnum.emoji) \(price)/\(duration)"
            button.setTitle(fullPrice, for: .normal)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
        }
    }
    
    private func buy(product: SKProduct, sender: Any) {
        DDLogInfo("Buying \"\(product.localizedTitle)\" (\(product.productIdentifier))...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    private func buyButtonPressed(_ sender: Any) {
        if let button = sender as? UIButton, let productEnum = allMoneyButtons[button], let product = products[productEnum] {
            buy(product: product, sender: sender)
        } else {
            DDLogError("Could not buy product via button \(sender)")
        }
    }
    
    fileprivate func progressToMaybeLater(sender: Any) {
        self.performSegue(withIdentifier: maybeLaterSegue, sender: sender)
    }
    
    @IBAction func restoreButtonPressed(_ sender: Any) {
        DDLogVerbose("Restore button pressed")
        SKPaymentQueue.default().transactions.forEach {
            DDLogVerbose("transaction in queue: \($0)")
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
    
    @IBAction func privacyButtonPressed(_ sender: Any) {
        let url = OTRBranding.projectURL.appendingPathComponent("/privacy")
        prompt(toShow: url, sender: sender)
    }
    
    @IBAction func termsButtonPressed(_ sender: Any) {
        let url = OTRBranding.projectURL.appendingPathComponent("/terms")
        prompt(toShow: url, sender: sender)
    }
}

extension PurchaseViewController: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            response.products.forEach {
                guard let product = $0.product else {
                    DDLogWarn("Unrecognized product: \($0)")
                    return
                }
                self.products[product] = $0
                DDLogInfo("Product \"\($0.localizedTitle)\" (\($0.productIdentifier)):  \($0.price.floatValue)")
            }
            self.refreshMoneyButtons()
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            DDLogError("Error loading products: \(error.localizedDescription)")
            MBProgressHUD.hide(for: self.view, animated: true)
        }
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

public class TransactionObserver: NSObject, SKPaymentTransactionObserver, SKRequestDelegate {
    @objc public static let shared = TransactionObserver()
    let paymentQueue = SKPaymentQueue.default()
    public var transactionSuccess: ((_ transaction: SKPaymentTransaction) -> Void)?
    
    deinit {
        stopObserving()
    }
    
    public static var receipt: Receipt? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        guard let receipt = Receipt(contentsOfURL: url) else {
            return nil
        }
        return receipt
    }
    
    public static var hasFreshReceipt: Bool {
        guard let receipt = self.receipt,
            let vendorId = UIDevice.current.identifierForVendor,
            let bundleIdentifier = receipt.bundleIdentifier,
            let receiptOpaque = receipt.opaqueValue,
            let bundleIdData = receipt.bundleIdentifierData,
            let sha1Hash = receipt.SHA1Hash,
            bundleIdentifier == "com.chrisballinger.ChatSecure"
            //let receiptVersion = receipt.appVersion,
            //let appVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String,
            //appVersion == receiptVersion
            else {
                return false
        }
        
        // https://stackoverflow.com/a/41598602/805882
        let uuid = vendorId.uuid // gives a uuid_t
        let uuidBytes = Mirror(reflecting: uuid).children.map({$0.1 as! UInt8}) // converts the tuple into an array
        let vendorData = Data(uuidBytes)
        
        var hashData = vendorData
        hashData.append(receiptOpaque)
        hashData.append(bundleIdData)
        let hash = (hashData as NSData).withSHA1Hash()
        
        if hash != sha1Hash {
            return false
        }
        return true
    }
    
    @objc public static var hasValidReceipt: Bool {
        guard let receipt = self.receipt,
              self.hasFreshReceipt else {
            return false
        }
        
        if let expiration = receipt.receiptExpirationDate,
            Date() > expiration {
            return false
        }
        
        var hasActiveSubscription = false
        if let iaps = receipt.inAppPurchaseReceipts {
            for iap in iaps {
                if let expiration = iap.subscriptionExpirationDate,
                    Date() > expiration,
                    let cancelationDate = iap.cancellationDate,
                    Date() > cancelationDate {
                    continue
                } else if iap.purchaseDate != nil {
                    hasActiveSubscription = true
                    break
                }
            }
        }
        
        return hasActiveSubscription
    }
    
    /** Start observing IAP transactions */
    @objc public func startObserving() {
        paymentQueue.add(self)
    }
    
    @objc public func stopObserving() {
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
                DDLogInfo("Transaction deferred: \(transaction)")
                break
            case .purchasing:
                DDLogInfo("Transaction purchasing: \(transaction)")
                break
            @unknown default:
                DDLogError("Unknown transaction state: \(transaction)")
                break
            }
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        DDLogInfo("Payment queue restore finished")
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        DDLogWarn("Payment queue restore failed with error \(error)")
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        DDLogInfo("Transaction complete: \(transaction)")
        SKPaymentQueue.default().finishTransaction(transaction)
        transactionSuccess?(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let _ = transaction.original?.payment.productIdentifier else {
            DDLogWarn("Cannot restore: No original transaction: \(transaction)")
            return
        }
        
        DDLogInfo("Transaction restored: \(transaction)")
        SKPaymentQueue.default().finishTransaction(transaction)
        transactionSuccess?(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        DDLogWarn("Transaction failed: \(transaction) \(String(describing: transaction.error))")
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    // MARK: SKRequestDelegate
    
    public func requestDidFinish(_ request: SKRequest) {
        DDLogInfo("Receipt refreshed: \(request)")
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        DDLogWarn("Receipt fetch error: \(request) \(error)")
    }
}
