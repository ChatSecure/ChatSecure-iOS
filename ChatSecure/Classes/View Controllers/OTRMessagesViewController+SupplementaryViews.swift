//
//  OTRMessagesViewController+NewDevice.swift
//  ChatSecureCore
//
//  Created by N-Pex on 26/2/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation
import OTRAssets

var OTRMessagesViewController_prototypeCellsAssociatedObject: UInt8 = 0

public extension OTRMessagesViewController {
    
    fileprivate var prototypeCells: [String:UICollectionReusableView] {
        get {
            return objc_getAssociatedObject(self, &OTRMessagesViewController_prototypeCellsAssociatedObject) as? [String:UICollectionReusableView] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &OTRMessagesViewController_prototypeCellsAssociatedObject, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    @objc public func collectionView(_ collectionView:UICollectionView, prototypeCellFromNib nibName:String, populationCallback:((UICollectionReusableView)->Void)?) -> UICollectionReusableView? {
        if prototypeCells[nibName] == nil {
            let nib = UINib(nibName: nibName, bundle: OTRAssets.resourcesBundle)
            if let prototype = nib.instantiate(withOwner: self, options: nil)[0] as? UICollectionReusableView {
                prototypeCells[nibName] = prototype
            }
        }
        if let prototype = prototypeCells[nibName] {
            if let populate = populationCallback {
                populate(prototype)
            }
            prototype.setNeedsLayout()
            prototype.layoutIfNeeded()
            prototype.frame = CGRect(x: 0, y: 0, width: collectionView.bounds.size.width, height: prototype.frame.size.height)
        }
        return prototypeCells[nibName]
    }
}

public extension OTRMessagesViewController {
    @objc public func didReceiveDeviceListUpdate(notification:Notification) {
        guard let notificationJid = notification.userInfo?["jid"] as? XMPPJID else { return }
        var buddy:OTRXMPPBuddy? = nil
        connections?.read.read({ (transaction) in
            buddy = self.threadObject(with: transaction) as? OTRXMPPBuddy
        })
        guard let bud = buddy else { return }
        if notificationJid.bare == bud.username {
            self.updateEncryptionState()
            checkForDeviceListUpdate(buddy: bud)
        }
    }
    
    @objc public func checkForDeviceListUpdate(buddy:OTRXMPPBuddy?) {
        guard let bud = buddy else { return }
        var hasNewDevice = false
        connections?.read.read({ (transaction) in
            let devices = OMEMODevice.allDevices(forParentKey: bud.uniqueId, collection: type(of: bud).collection, transaction: transaction)
            if OMEMODevice.filterNewDevices(devices, transaction: transaction).count > 0 {
                hasNewDevice = true
            }
        })
        if hasNewDevice, self.collectionView != nil {
            let lastSection = self.numberOfSections(in: collectionView) - 1
            let lastIndexPath = IndexPath(row: self.collectionView(collectionView, numberOfItemsInSection: lastSection) - 1, section: lastSection)
            if let message = self.message(at: lastIndexPath) {
                removeSupplementaryViews(ofType: OTRMessagesNewDeviceCell.reuseIdentifier)
                addSupplementaryView(forMessage: message, supplementaryView: OTRMessagesNewDeviceCell.reuseIdentifier)
            }
        }
    }
}
