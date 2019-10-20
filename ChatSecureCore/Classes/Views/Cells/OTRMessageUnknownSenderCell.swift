//
//  OTRMessageUnknownSenderCell.swift
//  ChatSecureCore
//
//  Created by N-Pex on 2017-11-27.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import BButton
import OTRAssets

@objc public class OTRMessagesUnknownSenderCell: UICollectionReusableView {
    @objc public static let reuseIdentifier = "unknownSenderCell"
    
    @objc @IBOutlet open weak var titleLabel:UILabel!
    @objc @IBOutlet open weak var avatarImageView:UIImageView!
    @objc @IBOutlet open weak var acceptButton:BButton!
    @objc @IBOutlet open weak var denyButton:BButton!
    @objc @IBOutlet open weak var nickLabel:UILabel!
    @objc @IBOutlet open weak var jidLabel:UILabel!
    @objc @IBOutlet open weak var mainStackView:UIStackView!
    @objc @IBOutlet open weak var occupantSection:UIView!
    @objc @IBOutlet open weak var buttonStackView:UIStackView!

    @objc open var senderJID:String?
    @objc open var senderDisplayName:String?

    @objc open var acceptButtonCallback:((_ senderJID:String?,_ senderDisplayName:String?) -> Void)?
    
    @objc open var denyButtonCallback:((_ senderJID:String?,_ senderDisplayName:String?) -> Void)? {
        didSet(callback) {
            if callback == nil {
                showDenyButton = false
            } else {
                showDenyButton = true
            }
        }
    }

    @objc open var collapsed:Bool {
        get {
            return mainStackView.arrangedSubviews.count == 1
        }
        set (collapse) {
            if !collapse, !mainStackView.arrangedSubviews.contains(occupantSection) {
                mainStackView.insertArrangedSubview(occupantSection, at: 1)
            } else if collapse, mainStackView.arrangedSubviews.contains(occupantSection) {
                mainStackView.removeArrangedSubview(occupantSection)
            }
            occupantSection.isHidden = collapse
        }
    }
    
    open var showDenyButton:Bool {
        get {
            return buttonStackView.arrangedSubviews.count > 1
        }
        set (show) {
            if show, !buttonStackView.arrangedSubviews.contains(denyButton) {
                buttonStackView.insertArrangedSubview(denyButton, at: 1)
            } else if !show, buttonStackView.arrangedSubviews.contains(denyButton) {
                buttonStackView.removeArrangedSubview(denyButton)
            }
            denyButton.isHidden = !show
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        acceptButton.setType(.success)
        acceptButton.setStyle(.bootstrapV3)
        acceptButton.addAwesomeIcon(.FACheck, beforeTitle: true)
        acceptButton.titleLabel?.font = acceptButton.titleLabel?.font.withSize(20)
        denyButton.setType(.danger)
        denyButton.setStyle(.bootstrapV3)
        denyButton.addAwesomeIcon(.FATimes, beforeTitle: true)
        denyButton.titleLabel?.font = acceptButton.titleLabel?.font.withSize(20)
        collapsed = false
        showDenyButton = false // For now
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        for view in subviews {
            if let label = view as? UILabel {
                if label.numberOfLines == 0 {
                    label.preferredMaxLayoutWidth = label.bounds.width
                }
            }
        }
    }
    
    @IBAction func didTapAccept(_ sender: Any) {
        if let callback = self.acceptButtonCallback {
            callback(self.senderJID, self.senderDisplayName)
        }
    }
    
    @IBAction func didTapDeny(_ sender: Any) {
        if let callback = self.denyButtonCallback {
            callback(self.senderJID, self.senderDisplayName)
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        collapsed = false
        showDenyButton = false
        titleLabel.text = nil
        nickLabel.text = nil
        jidLabel.text = nil
        avatarImageView.image = nil
    }
    
    @objc open func populate(message:OTRMessageProtocol & JSQMessageData,
                             account:OTRAccount?,
                             connection:YapDatabaseConnection,
                             acceptButtonCallback:((_ senderJID:String?,_ senderDisplayName:String?) -> Void)?,
                             denyButtonCallback:((_ senderJID:String?,_ senderDisplayName:String?) -> Void)?,
                             avatarData:JSQMessageAvatarImageDataSource?) {
        titleLabel.text = String(format: ADD_FRIEND_TO_AUTO_DOWNLOAD(), message.senderDisplayName())
        nickLabel.text = message.senderDisplayName()
        jidLabel.text = nil
        collapsed = true
        if let groupDownloadMessage = message as? OTRGroupDownloadMessage {
            var roomOccupant:OTRXMPPRoomOccupant? = nil
            if let senderJIDString = groupDownloadMessage.senderJID,
                let roomJIDString = groupDownloadMessage.roomJID,
                let senderJID = XMPPJID(string: senderJIDString),
                let roomJID = XMPPJID(string:roomJIDString),
                let account = account {
                connection.read({ (transaction) in
                    roomOccupant = OTRXMPPRoomOccupant.occupant(jid: senderJID, realJID: nil, roomJID: roomJID, accountId: account.uniqueId, createIfNeeded: false, transaction: transaction)
                })
                if let occupant = roomOccupant, let realJid = occupant.realJID {
                    jidLabel.text = realJid.bare
                    if jidLabel.text?.count == 0 {
                        jidLabel.text = groupDownloadMessage.senderJID
                    }
                    self.senderJID = realJid.bare
                    self.senderDisplayName = occupant.displayText()
                    self.acceptButtonCallback = acceptButtonCallback
                    self.denyButtonCallback = denyButtonCallback
                    collapsed = false
                }
            }
        }
        if let avatarData = avatarData {
            avatarImageView.image = avatarData.avatarImage()
        }
    }
}
