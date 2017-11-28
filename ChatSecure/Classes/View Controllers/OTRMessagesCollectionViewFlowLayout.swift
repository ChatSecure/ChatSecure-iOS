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

@objc public class OTRMessagesCollectionSupplementaryViewInfo: NSObject {
    public var kind:String
    public var height:CGFloat

    @objc public init(kind:String, height:CGFloat) {
        self.kind = kind
        self.height = height
        super.init()
    }
}

@objc public protocol OTRMessagesCollectionViewFlowLayoutSupplementaryViewProtocol {
    func supplementaryViewsForCellAtIndexPath(_ indexPath: IndexPath) -> [OTRMessagesCollectionSupplementaryViewInfo]?
}

@objc open class OTRMessagesCollectionViewFlowLayout:JSQMessagesCollectionViewFlowLayout {
    
    @objc open weak var sizeDelegate:OTRMessagesCollectionViewFlowLayoutSizeProtocol?
    @objc open weak var supplementaryViewDelegate:OTRMessagesCollectionViewFlowLayoutSupplementaryViewProtocol?

    @objc override open func messageBubbleSizeForItem(at indexPath: IndexPath!) -> CGSize {
        guard let delegate = self.sizeDelegate, !delegate.hasBubbleSizeForCellAtIndexPath(indexPath) else {
            return super.messageBubbleSizeForItem(at: indexPath)
        }
        
        //Set width to one because of an Assert inside of JSQMessagesViewController
        return CGSize(width: 1, height: 0)
    }
    
    open override var collectionViewContentSize: CGSize {
        var size = super.collectionViewContentSize
        if let delegate = self.supplementaryViewDelegate {
            for section in 0..<self.collectionView.numberOfSections {
                for item in 0..<self.collectionView.numberOfItems(inSection: section) {
                    if let views = delegate.supplementaryViewsForCellAtIndexPath(IndexPath(item: item, section: section)) {
                        for view in views {
                            size.height += view.height
                        }
                    }
                }
            }
        }
        return size
    }
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard var attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        var offset:CGFloat = 0
        for attribute in attributes {
            if (attribute.representedElementCategory == UICollectionElementCategory.cell) {
                attribute.frame = attribute.frame.offsetBy(dx: 0, dy: offset)
                if let delegate = self.supplementaryViewDelegate {
                    if let views = delegate.supplementaryViewsForCellAtIndexPath(attribute.indexPath) {
                        for view in views {
                            offset += view.height
                            let suppViewAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: view.kind, with: attribute.indexPath)
                            suppViewAttrs.frame = CGRect(x: attribute.frame.origin.x, y: attribute.frame.origin.y+attribute.frame.size.height, width: attribute.frame.size.width, height: view.height)
                            attributes.append(suppViewAttrs)
                        }
                    }
                }
            }
        }
        return attributes
    }
}
