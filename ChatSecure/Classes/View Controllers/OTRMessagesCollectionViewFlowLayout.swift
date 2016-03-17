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
    func hasBubbleSizeForCellAtIndexPath(indexPath: NSIndexPath) -> Bool
}

public class OTRMessagesCollectionViewFlowLayout:JSQMessagesCollectionViewFlowLayout {
    
    public weak var sizeDelegate:OTRMessagesCollectionViewFlowLayoutSizeProtocol?
    
    override public func messageBubbleSizeForItemAtIndexPath(indexPath: NSIndexPath!) -> CGSize {
        guard let delegate = self.sizeDelegate where !delegate.hasBubbleSizeForCellAtIndexPath(indexPath) else {
            return super.messageBubbleSizeForItemAtIndexPath(indexPath)
        }
        
        //Set width to one because of an Assert inside of JSQMessagesViewController
        return CGSizeMake(1, 0)
    }
    
}