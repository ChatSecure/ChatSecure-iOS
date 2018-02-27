//
//  OTRMessagesViewController+NewDevice.swift
//  ChatSecureCore
//
//  Created by N-Pex on 26/2/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation
import OTRAssets

var OTRMessagesViewController_supplementaryViewsAssociatedObject: UInt8 = 0
var OTRMessagesViewController_prototypeCellsAssociatedObject: UInt8 = 0

extension OTRMessagesViewController: OTRMessagesCollectionViewFlowLayoutSupplementaryViewProtocol {

    fileprivate var supplementaryViewNibs:[String:String] {
        return [
            OTRMessagesUnknownSenderCell.reuseIdentifier:"OTRMessageUnknownSenderCell",
            OTRMessagesNewDeviceCell.reuseIdentifier:"OTRMessageNewDeviceCell"
        ]
    }
    
    fileprivate var supplementaryViews:[String:[String]] {
        get {
            return objc_getAssociatedObject(self, &OTRMessagesViewController_supplementaryViewsAssociatedObject) as? [String:[String]] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &OTRMessagesViewController_supplementaryViewsAssociatedObject, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc public func registerSupplementaryViewTypes(collectionView:UICollectionView) {
        for (identifier,nibName) in supplementaryViewNibs {
            let nib = UINib(nibName: nibName, bundle: OTRAssets.resourcesBundle)
            collectionView.register(nib, forSupplementaryViewOfKind: identifier, withReuseIdentifier: identifier)
        }
    }
    
    public func supplementaryViewsForCellAtIndexPath(_ indexPath: IndexPath) -> [OTRMessagesCollectionSupplementaryViewInfo]? {
        guard let message = message(at: indexPath) else { return nil }
        let supplementaryViews = self.supplementaryViews[message.uniqueId]
        
        var supplementaryViewsInfo:[OTRMessagesCollectionSupplementaryViewInfo] = []
        
        if isGroupChat(),
            let message = message as? OTRGroupDownloadMessage,
            let error = message.messageError as NSError?,
            error.isAutomaticDownloadError,
            !automaticURLFetchingDisabled
        {
            // We may have become friends since this message was sent, see if we can find a buddy
            var areFriendsNow = false
            self.connections?.read.read({ (transaction) in
                if let buddy = message.buddy(with: transaction) {
                    areFriendsNow = (buddy.trustLevel == .roster)
                }
            })
            if !areFriendsNow {
                
                var tag:String? = nil
                if let buddyUniqueId = message.buddyUniqueId {
                    tag = String(format: "%@-%@", buddyUniqueId, OTRMessagesUnknownSenderCell.reuseIdentifier)
                }
                if let supplementaryViewInfo = createSuplementaryViewInfo(collectionView, kind:OTRMessagesUnknownSenderCell.reuseIdentifier, populationCallback: { (cell) in
                    self.populateUnknownSenderCell(cell: cell, indexPath: indexPath, forSizingOnly: true)
                }, tag: tag, tagBehavior: .showLast) {
                    supplementaryViewsInfo.append(supplementaryViewInfo)
                }
            }
        }
        
        if let supplementaryViews = supplementaryViews {
            for view in supplementaryViews {
                if view == OTRMessagesNewDeviceCell.reuseIdentifier {
                    if let supplementaryViewInfo = createSuplementaryViewInfo(collectionView, kind: OTRMessagesNewDeviceCell.reuseIdentifier, populationCallback: { (cell) in
                        self.populateNewDeviceCell(cell: cell, indexPath: indexPath, forSizingOnly: true)
                    }, tag: nil, tagBehavior: .none) {
                        supplementaryViewsInfo.append(supplementaryViewInfo)
                    }
                }
            }
        }
        
        if supplementaryViewsInfo.count > 0 {
            return supplementaryViewsInfo
        }
        return nil
    }
    
    @objc open func removeAllSupplementaryViews() {
        supplementaryViews = [:]
    }
    
    open func removeSupplementaryViewsOfType(type:String) {
        for (key,value) in self.supplementaryViews {
            var newValue = value
            if let index = newValue.index(of: type) {
                newValue.remove(at: index)
                supplementaryViews[key] = newValue
            }
        }
    }
    
    open func addSupplementaryViewForMessage(message:OTRMessageProtocol, supplementaryView type:String) {
        var value = self.supplementaryViews[message.uniqueId]
        if value == nil {
            value = [type]
        } else {
            value?.append(type)
        }
        self.supplementaryViews[message.uniqueId] = value
    }

    open override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == OTRMessagesUnknownSenderCell.reuseIdentifier {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath)
            populateUnknownSenderCell(cell: cell, indexPath: indexPath, forSizingOnly: false)
            return cell
        } else if kind == OTRMessagesNewDeviceCell.reuseIdentifier {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath)
            populateNewDeviceCell(cell: cell, indexPath: indexPath, forSizingOnly: false)
            return cell
        }
        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
}

public extension OTRMessagesViewController {
    
    fileprivate var prototypeCells: [String:UICollectionReusableView] {
        get {
            return objc_getAssociatedObject(self, &OTRMessagesViewController_prototypeCellsAssociatedObject) as? [String:UICollectionReusableView] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &OTRMessagesViewController_prototypeCellsAssociatedObject, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    fileprivate func prototypeCell(kind:String) -> UICollectionReusableView? {
        if prototypeCells[kind] == nil, let nibName = supplementaryViewNibs[kind] {
            let nib = UINib(nibName: nibName, bundle: OTRAssets.resourcesBundle)
            if let prototype = nib.instantiate(withOwner: self, options: nil)[0] as? UICollectionReusableView {
                prototypeCells[kind] = prototype
            }
        }
        return prototypeCells[kind]
    }
    
    fileprivate func createSuplementaryViewInfo(_ collectionView:UICollectionView,
                                            kind:String,
                                            populationCallback:((UICollectionReusableView)->Void)?,
                                            tag:String?,
                                            tagBehavior:OTRMessagesCollectionSupplementaryViewInfo.SupplementaryViewTagBehavior) -> OTRMessagesCollectionSupplementaryViewInfo? {
        if let prototype = prototypeCell(kind: kind) {
            if let populate = populationCallback {
                populate(prototype)
            }
            prototype.setNeedsLayout()
            prototype.layoutIfNeeded()
            prototype.frame = CGRect(x: 0, y: 0, width: collectionView.bounds.size.width, height: prototype.frame.size.height)
            let height = prototype.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height + 1
            return OTRMessagesCollectionSupplementaryViewInfo(kind: kind, height: height, tag: tag, tagBehavior: tagBehavior)
        }
        return nil
    }

    fileprivate func populateUnknownSenderCell(cell:UICollectionReusableView?, indexPath:IndexPath, forSizingOnly:Bool) {
        guard let unknownSenderCell = cell as? OTRMessagesUnknownSenderCell else { return }
        guard let message = self.message(at: indexPath) else { return }

        var account:OTRXMPPAccount? = nil
        connections?.read.read({ (transaction) in
            account = self.account(with: transaction)
        })
        if let account = account, let readConnection = connections?.read {
            let dataSource:JSQMessagesCollectionViewDataSource = self
            let avatarData = dataSource.collectionView(self.collectionView, avatarImageDataForItemAt: indexPath)
            
            // Set callback only for "real" cell, not when sizing
            var acceptButtonCallback:((String?,String?) -> Void)? = nil
            if !forSizingOnly {
                acceptButtonCallback = {[unowned self] (senderJIDString, senderDisplayName) in
                    guard let senderJIDString = senderJIDString,
                        let senderJID = XMPPJID(string: senderJIDString) else { return }
                    if let manager = OTRProtocolManager.shared.protocol(for: account) as? XMPPManager {
                        manager.addToRoster(with: senderJID, displayName: senderDisplayName)
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
            
            unknownSenderCell.populate(message: message, account: account, connection: readConnection, acceptButtonCallback: acceptButtonCallback, denyButtonCallback: nil, avatarData:avatarData)
        }
    }
    
    fileprivate func populateNewDeviceCell(cell:UICollectionReusableView?, indexPath:IndexPath, forSizingOnly:Bool) {
        guard let newDeviceCell = cell as? OTRMessagesNewDeviceCell else { return }
        var buddy:OTRXMPPBuddy? = nil
        self.connections?.read.read({ (transaction) in
            buddy = self.threadObject(with: transaction) as? OTRXMPPBuddy
        })
        if let buddy = buddy {
            newDeviceCell.populate(buddy: buddy)
        }
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
                removeSupplementaryViewsOfType(type: OTRMessagesNewDeviceCell.reuseIdentifier)
                addSupplementaryViewForMessage(message: message, supplementaryView: OTRMessagesNewDeviceCell.reuseIdentifier)
            }
        }
    }
}
