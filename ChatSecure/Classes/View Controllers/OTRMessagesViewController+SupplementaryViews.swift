//
//  OTRMessagesViewController+NewDevice.swift
//  ChatSecureCore
//
//  Created by N-Pex on 26/2/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation
import OTRAssets


@objc public class SupplementaryViewHandler: NSObject, OTRMessagesCollectionViewFlowLayoutSupplementaryViewProtocol {
    
    @objc public let connections: DatabaseConnections
    @objc public let viewHandler: OTRYapViewHandler
    @objc public let collectionView: JSQMessagesCollectionView
    
    @objc public var newDeviceViewActionButtonCallback:((_ buddyUniqueId:String?) -> Void)?
    
    @objc public init(collectionView: JSQMessagesCollectionView,
                      viewHandler: OTRYapViewHandler,
                      connections: DatabaseConnections) {
        self.collectionView = collectionView
        self.viewHandler = viewHandler
        self.connections = connections
        super.init()
        registerSupplementaryViewTypes(collectionView: collectionView)
    }
    
    fileprivate var supplementaryViewNibs:[String:String] {
        return [
            OTRMessagesUnknownSenderCell.reuseIdentifier:"OTRMessageUnknownSenderCell",
            OTRMessagesNewDeviceCell.reuseIdentifier:"OTRMessageNewDeviceCell"
        ]
    }
    
    fileprivate var supplementaryViews:[String:[String]] = [:]
    
    @objc public func registerSupplementaryViewTypes(collectionView:UICollectionView) {
        for (identifier,nibName) in supplementaryViewNibs {
            let nib = UINib(nibName: nibName, bundle: OTRAssets.resourcesBundle)
            collectionView.register(nib, forSupplementaryViewOfKind: identifier, withReuseIdentifier: identifier)
        }
    }
    
    public func supplementaryViewsForCellAtIndexPath(_ indexPath: IndexPath, message: OTRMessageProtocol) -> [OTRMessagesCollectionSupplementaryViewInfo]? {
        let supplementaryViews = self.supplementaryViews[message.uniqueId]
        
        var automaticURLFetchingDisabled = true
        connections.ui.fetch {
            automaticURLFetchingDisabled = (message.buddy(with: $0)?.account(with: $0) as? OTRXMPPAccount)?.disableAutomaticURLFetching ?? true
        }
        
        var supplementaryViewsInfo:[OTRMessagesCollectionSupplementaryViewInfo] = []
        
        if let message = message as? OTRGroupDownloadMessage,
            let error = message.messageError as NSError?,
            error.isAutomaticDownloadError,
            !automaticURLFetchingDisabled
        {
            // We may have become friends since this message was sent, see if we can find a buddy
            var areFriendsNow = false
            self.connections.read.read({ (transaction) in
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

    
    @objc open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView? {
        if kind == OTRMessagesUnknownSenderCell.reuseIdentifier {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath)
            populateUnknownSenderCell(cell: cell, indexPath: indexPath, forSizingOnly: false)
            return cell
        } else if kind == OTRMessagesNewDeviceCell.reuseIdentifier {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath)
            populateNewDeviceCell(cell: cell, indexPath: indexPath, forSizingOnly: false)
            return cell
        }
        return nil
    }

    fileprivate var prototypeCells: [String:UICollectionReusableView] = [:]
    
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
    
    private func fetchMessageInfo(at indexPath: IndexPath) -> (JSQMessageData & OTRMessageProtocol, OTRThreadOwner, OTRXMPPAccount)? {
        guard let message = self.viewHandler.object(indexPath) as? (JSQMessageData & OTRMessageProtocol) else { return nil }
        var thread: OTRThreadOwner?
        var account: OTRXMPPAccount?
        connections.ui.read {
            thread = message.threadOwner(with: $0)
            account = thread?.account(with: $0) as? OTRXMPPAccount
        }
        if let thread = thread,
            let account = account {
            return (message, thread, account)
        } else {
            return nil
        }
    }

    fileprivate func populateUnknownSenderCell(cell:UICollectionReusableView?, indexPath:IndexPath, forSizingOnly:Bool) {
        guard let unknownSenderCell = cell as? OTRMessagesUnknownSenderCell else { return }
        guard let (message, _, account) = fetchMessageInfo(at: indexPath) else { return }
        
        let avatarData = self.collectionView.dataSource.collectionView(self.collectionView, avatarImageDataForItemAt: indexPath)
        
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
        
        unknownSenderCell.populate(message: message, account: account, connection: self.connections.ui, acceptButtonCallback: acceptButtonCallback, denyButtonCallback: nil, avatarData:avatarData)
    }
    
    fileprivate func populateNewDeviceCell(cell:UICollectionReusableView?, indexPath:IndexPath, forSizingOnly:Bool) {
        guard let newDeviceCell = cell as? OTRMessagesNewDeviceCell,
        let (_, thread, _) = fetchMessageInfo(at: indexPath) else { return }
        
        if let buddy = thread as? OTRXMPPBuddy {
            var actionButtonCallback:((String?) -> Void)? = nil
            if !forSizingOnly {
                actionButtonCallback = self.newDeviceViewActionButtonCallback
            }
            newDeviceCell.populate(buddy: buddy, actionButtonCallback: actionButtonCallback)
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
        guard let bud = buddy, let jid = buddy?.bareJID else { return }
        var newDevices: [OMEMODevice] = []
        var omemo: OMEMOModule?
        connections?.read.read({ (transaction) in
            omemo = self.xmppManager(with: transaction)?.omemoSignalCoordinator?.omemoModule
            let devices = OMEMODevice.allDevices(forParentKey: bud.uniqueId, collection: type(of: bud).collection, transaction: transaction)
            newDevices = OMEMODevice.filterNewDevices(devices, transaction: transaction)
        })

        // Not the right place for this, but we need to fetch missing bundle data
        // to show fingerprints. Hopefully they are fetched in time.
        newDevices.forEach({ (device) in
            if device.publicIdentityKeyData == nil {
                omemo?.fetchBundle(forDeviceId: UInt32(truncating: device.deviceId), jid: jid, elementId: nil)
            }
        })
        
        if newDevices.count > 0, self.collectionView != nil {
            if let lastIndexPath = collectionView.lastIndexPath(), let message = self.message(at: lastIndexPath) {
                supplementaryViewHandler?.removeSupplementaryViewsOfType(type: OTRMessagesNewDeviceCell.reuseIdentifier)
                supplementaryViewHandler?.addSupplementaryViewForMessage(message: message, supplementaryView: OTRMessagesNewDeviceCell.reuseIdentifier)
            }
        }
    }
}

extension UICollectionView {
    func lastIndexPath() -> IndexPath? {
        for sectionIndex in (0..<self.numberOfSections).reversed() {
            if self.numberOfItems(inSection: sectionIndex) > 0 {
                return IndexPath.init(item: self.numberOfItems(inSection: sectionIndex)-1, section: sectionIndex)
            }
        }
        return nil
    }
}
