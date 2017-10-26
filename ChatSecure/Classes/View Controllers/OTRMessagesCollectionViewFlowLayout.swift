//
//  OTRMessagesCollectionViewFlowLayout.swift
//  ChatSecure
//
//  Created by David Chiles on 3/4/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

import JSQMessagesViewController

@objc public protocol OTRMessagesCollectionViewFlowLayoutSizeProtocol {
    func hasBubbleSizeForCellAtIndexPath(_ indexPath: IndexPath) -> Bool
}

@objc open class OTRMessagesCollectionViewFlowLayout:JSQMessagesCollectionViewFlowLayout {
    
    @objc open weak var sizeDelegate:OTRMessagesCollectionViewFlowLayoutSizeProtocol?
    
    @objc override open func messageBubbleSizeForItem(at indexPath: IndexPath!) -> CGSize {
        guard let delegate = self.sizeDelegate, !delegate.hasBubbleSizeForCellAtIndexPath(indexPath) else {
            return super.messageBubbleSizeForItem(at: indexPath)
        }
        
        //Set width to one because of an Assert inside of JSQMessagesViewController
        return CGSize(width: 1, height: 0)
    }
    
}
