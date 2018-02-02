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

    /* For caching supplementary view information. The 64bit keys of this dictionary are formed by or:ing section and item together */
    private var supplementaryViews:[UInt64:[OTRMessagesCollectionSupplementaryViewInfo]] = [:]
    
    @objc override open func messageBubbleSizeForItem(at indexPath: IndexPath!) -> CGSize {
        guard let delegate = self.sizeDelegate, !delegate.hasBubbleSizeForCellAtIndexPath(indexPath) else {
            return super.messageBubbleSizeForItem(at: indexPath)
        }
        
        //Set width to one because of an Assert inside of JSQMessagesViewController
        return CGSize(width: 1, height: 0)
    }
    
    override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if context.invalidateEverything || context.invalidateDataSourceCounts {
            self.supplementaryViews.removeAll()
            if let delegate = self.supplementaryViewDelegate {
                for section in 0..<self.collectionView.numberOfSections {
                    for item in 0..<self.collectionView.numberOfItems(inSection: section) {
                        if let views = delegate.supplementaryViewsForCellAtIndexPath(IndexPath(item: item, section: section)) {
                            let index = cacheIndexFor(item: item, section: section)
                            supplementaryViews[index] = views
                        }
                    }
                }
            }
        } else {
            for indexPath in context.invalidatedItemIndexPaths ?? [] {
                let index = cacheIndexFor(item: indexPath.item, section: indexPath.section)
                self.supplementaryViews[index] = nil
                if let delegate = self.supplementaryViewDelegate {
                    if let views = delegate.supplementaryViewsForCellAtIndexPath(IndexPath(item: indexPath.item, section: indexPath.section)) {
                        supplementaryViews[index] = views
                    }
                }
            }
        }
        super.invalidateLayout(with: context)
    }
    
    open override var collectionViewContentSize: CGSize {
        var size = super.collectionViewContentSize
        
        // Add the height for all supplementary views as well
        for views in supplementaryViews.values {
            for view in views {
                size.height += view.height
            }
        }
        return size
    }
    
    private func cacheIndexFor(item: Int, section: Int) -> UInt64 {
        return (UInt64(section) << 32) | UInt64(item)
    }
    
    /** For a given indexPath, find out how much all supplementary views above it will offset its layout */
    private func accumulatedSupplementaryViewHeight(at indexPath:IndexPath) -> CGFloat {
        var ret:CGFloat = 0
        let cacheIndex = cacheIndexFor(item: indexPath.item, section: indexPath.section)
        for item in self.supplementaryViews where item.key < cacheIndex {
            for view in item.value {
                ret += view.height
            }
        }
        return ret
    }
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        var outAttributes:[UICollectionViewLayoutAttributes] = []
        for a in attributes {
            if let attribute = a.copy() as? UICollectionViewLayoutAttributes {
                outAttributes.append(attribute)
                
                // Offset by supplementary views above it in the layout
                let offset = accumulatedSupplementaryViewHeight(at: attribute.indexPath)
                attribute.frame = attribute.frame.offsetBy(dx: 0, dy: offset)
                
                // If this is a cell attribute, check if we should add supplementary views below it
                if (attribute.representedElementCategory == UICollectionElementCategory.cell) {
                    let cacheIndex = cacheIndexFor(item: attribute.indexPath.item, section: attribute.indexPath.section)
                    if let views = self.supplementaryViews[cacheIndex] {
                        var viewOffset:CGFloat = 0
                        for view in views {
                            let suppViewAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: view.kind, with: attribute.indexPath)
                            suppViewAttrs.frame = CGRect(x: attribute.frame.origin.x, y: attribute.frame.origin.y+attribute.frame.size.height+viewOffset, width: attribute.frame.size.width, height: view.height)
                            outAttributes.append(suppViewAttrs)
                            viewOffset += view.height
                        }
                    }
                }
            }
        }
        return outAttributes
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let superAttributes = super.layoutAttributesForItem(at: indexPath) else {return nil}
        let offset = accumulatedSupplementaryViewHeight(at: indexPath)
        superAttributes.frame = superAttributes.frame.offsetBy(dx: 0, dy: offset)
        return superAttributes.copy() as? UICollectionViewLayoutAttributes
    }
    
    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let cacheIndex = cacheIndexFor(item: indexPath.item, section: indexPath.section)
        if let views = self.supplementaryViews[cacheIndex], let itemAttrs = self.layoutAttributesForItem(at: indexPath) {
            var viewOffset:CGFloat = 0
            for view in views {
                if view.kind == elementKind {
                    let suppViewAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: view.kind, with: indexPath)
                    suppViewAttrs.frame = CGRect(x: itemAttrs.frame.origin.x, y: itemAttrs.frame.origin.y+itemAttrs.frame.size.height+viewOffset, width: itemAttrs.frame.size.width, height: view.height)
                    return suppViewAttrs
                }
                viewOffset += view.height
            }
        }
        let ret = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        if ret == nil {
            // Must return something, so make this invisible!
            let attrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
            attrs.frame = CGRect.zero
            return attrs
        }
        return ret
    }
}
