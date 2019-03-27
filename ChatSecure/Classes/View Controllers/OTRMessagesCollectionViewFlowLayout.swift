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
    public var tag:String?
    @objc public enum SupplementaryViewTagBehavior: Int {
        case none
        case showFirst
        case showLast
    }
    public var tagBehavior:SupplementaryViewTagBehavior = .none
    
    // The key is set by the layout to tie this view info to an actual IndexPath.
    var key:UInt64

    @objc public init(kind:String, height:CGFloat) {
        self.kind = kind
        self.height = height
        self.key = 0
        super.init()
    }
    
    @objc public convenience init(kind:String, height:CGFloat, tag:String?, tagBehavior:SupplementaryViewTagBehavior) {
        self.init(kind: kind, height: height)
        self.tag = tag
        self.tagBehavior = tagBehavior
    }
}

@objc public protocol OTRMessagesCollectionViewFlowLayoutSupplementaryViewProtocol {
    func supplementaryViewsForCellAtIndexPath(_ indexPath: IndexPath, message: OTRMessageProtocol) -> [OTRMessagesCollectionSupplementaryViewInfo]?
}

@objc open class OTRMessagesCollectionViewFlowLayout:JSQMessagesCollectionViewFlowLayout {
    
    @objc open weak var viewHandler: OTRYapViewHandler?
    @objc open weak var sizeDelegate:OTRMessagesCollectionViewFlowLayoutSizeProtocol?
    @objc open weak var supplementaryViewDelegate:OTRMessagesCollectionViewFlowLayoutSupplementaryViewProtocol?

    /* For caching supplementary view information. The 64bit keys of this dictionary are formed by or:ing section and item together */
    private var supplementaryViews:[UInt64:[OTRMessagesCollectionSupplementaryViewInfo]] = [:]
    private var supplementaryViewsByTag:[String:OTRMessagesCollectionSupplementaryViewInfo] = [:]
    
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
            self.supplementaryViewsByTag.removeAll()
            for section in 0..<self.collectionView.numberOfSections {
                for item in 0..<self.collectionView.numberOfItems(inSection: section) {
                    addSupplementaryViewsFor(item: item, section: section)
                }
            }
        } else {
            for indexPath in context.invalidatedItemIndexPaths ?? [] {
                addSupplementaryViewsFor(item: indexPath.item, section: indexPath.section)
            }
        }
        super.invalidateLayout(with: context)
    }
    
    private func addSupplementaryViewsFor(item:Int, section:Int) {
        let index = cacheIndexFor(item: item, section: section)
        let indexPath = IndexPath(item: item, section: section)
        let message = viewHandler?.object(indexPath) as? OTRMessageProtocol
        self.supplementaryViews[index] = nil
        if let delegate = self.supplementaryViewDelegate, let message = message {
            if var views = delegate.supplementaryViewsForCellAtIndexPath(IndexPath(item: item, section: section), message: message), views.count > 0 {
                for i in stride(from:views.count-1, to:0, by: -1) {
                    let view = views[i]
                    view.key = index
                    if !applyTagBehavior(view: view) {
                        views.remove(at: i)
                    }
                }
                supplementaryViews[index] = views
            }
        }
    }
    
    // Apply current tag behavior of the supplementary view. For each tag we store the "latest" supplementary view that this tag is mapped to. Based on the tagBehavior we update that mapping below and remove other supplementary views with the same tag, so that only one exists at any given time.
    // Note that view.key must be set at this point
    // Returns a boolean indicating whether this view should be added or not - false to ignore it
    private func applyTagBehavior(view:OTRMessagesCollectionSupplementaryViewInfo) -> Bool {
        guard let tag = view.tag, view.tagBehavior != .none else { return true }
        
        if let currentTagView = supplementaryViewsByTag[tag] {
            let currentTagIndexPath = currentTagView.key
            if (view.tagBehavior == .showFirst && view.key < currentTagIndexPath) || (view.tagBehavior == .showLast && view.key > currentTagIndexPath) {
                
                // Remove previously mapped view
                if var suppViews = supplementaryViews[currentTagIndexPath] {
                    if let suppViewIndex = suppViews.firstIndex(of: currentTagView) {
                        suppViews.remove(at: suppViewIndex)
                        supplementaryViews[currentTagIndexPath] = suppViews
                    }
                }
                
                // Store new index path of this tag
                supplementaryViewsByTag[tag] = view
            } else {
                // Remove this view, we are showing another view for this tag already
                return false
            }
        } else {
            // Nothing stored previously
            supplementaryViewsByTag[tag] = view
        }
        return true
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
                if (attribute.representedElementCategory == UICollectionView.ElementCategory.cell) {
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
        
        // All the views that super returns may be offset by all supplementary views above. We need to walk backwards from the "first" index path returned by super and add any views intersecting the rect. First find out the index path of the first view, or if none: the last valid index path of the collectionView.
        var indexPath = attributes.first?.indexPath
        if indexPath == nil {
            var section = collectionView.numberOfSections - 1
            while section >= 0 {
                let item = collectionView.numberOfItems(inSection: section)
                if item > 0 {
                    indexPath = IndexPath(item: item, section: section)
                    break
                }
                section -= 1
            }
        }
        
        // Then walk backwards, adding views as long as they are actually intersecting the "rect" parameter.
        if let indexPath = indexPath {
            var section = indexPath.section
            var item = indexPath.item
            while true {
                if item == 0 && section > 0 {
                    section -= 1
                    item = collectionView.numberOfItems(inSection: section) - 1
                } else if item > 0 {
                    item -= 1
                } else {
                    break
                }
                guard let itemAttrs = layoutAttributesForItem(at: IndexPath(item: item, section: section)) else { break }
                if itemAttrs.frame.intersects(rect) {
                    outAttributes.insert(itemAttrs, at: 0)
                } else {
                    break
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
