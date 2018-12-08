//
//  OTRVerticalStackView.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-08-21.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import PureLayout

@objc public class OTRVerticalStackView: UITableView, UITableViewDataSource, UITableViewDelegate {
    
    @objc (OTRVerticalStackViewGravity) public enum Gravity: Int {
        case top = 0
        case middle = 1
        case bottom = 2
    }
    
    private class ViewInfo: NSObject {
        public var view:UIView?
        public var gravity:Gravity = .middle
        public var height:CGFloat = 0
        public var callback:(() -> Void)?
        public var identifier:String?
        public var hidden = false
    }
    
    private var stackedSubviews:[ViewInfo] = []
    private var visibleSubviews:[ViewInfo] = []
    private var initialized:Bool = false
    
    public convenience init() {
        self.init(frame: CGRect.zero, style: .plain)
    }
    
    @objc public func addStackedSubview(_ view:UIView) {
        addStackedSubview(view, identifier:nil, gravity: .middle, height: 0, callback: nil)
    }

    @objc public func addStackedSubview(_ view:UIView, identifier:String?, gravity:Gravity) {
        addStackedSubview(view, identifier:identifier, gravity: gravity, height: 0, callback: nil)
    }

    @objc public func addStackedSubview(_ view:UIView, identifier:String?, gravity:Gravity, height:CGFloat) {
        addStackedSubview(view, identifier:identifier, gravity: gravity, height: height, callback: nil)
    }

    @objc public func addStackedSubview(_ view:UIView, identifier:String?, gravity:Gravity, height:CGFloat, callback:(() -> Void)?) {
        
        if !initialized {
            initialized = true
            self.delegate = self
            self.dataSource = self
        }
        
        var subview = view
        var subviewHeight = height
        if subviewHeight == 0 {
            subviewHeight = subview.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        }
        if !(subview is UITableViewCell) {
            let cell = UITableViewCell()
            cell.backgroundColor = self.backgroundColor
            
            if subview is UISearchBar {
                // The UISearchBar uses all kinds of adding/removing views, so put that
                // in a wrapper we have control over.
                let wrapperView = UIView()
                wrapperView.addSubview(subview)
                subview = wrapperView
            }
            cell.contentView.addSubview(subview)
            subview.autoPinEdge(.top, to: .top, of: cell.contentView)
            subview.autoPinEdge(.left, to: .left, of: cell.contentView)
            subview.autoPinEdge(.right, to: .right, of: cell.contentView)
            subview.autoPinEdge(.bottom, to: .bottom, of: cell.contentView)
            subview = cell
        }
        
        let info = ViewInfo()
        info.view = subview
        info.gravity = gravity
        info.height = subviewHeight
        info.callback = callback
        info.identifier = identifier
        stackedSubviews.append(info)
        update()
    }

    private func update() {
        // Resort
        visibleSubviews = stackedSubviews.filter({ (viewInfo) -> Bool in
            return !viewInfo.hidden
        }).sorted(by: { (view1:ViewInfo, view2:ViewInfo) -> Bool in
            let view1Gravity = view1.gravity
            let view2Gravity = view2.gravity
            if view1Gravity == view2Gravity {
                return false
            }
            switch (view1Gravity, view2Gravity) {
            case (.middle, .top): return false
            case (.bottom, .top): return false
            case (.bottom, .middle): return false
            default: return true
            }
        })
        
        // Set our height
        var totalHeight:CGFloat = 0
        for viewInfo in visibleSubviews {
            totalHeight += viewInfo.height
        }
        frame = self.frame
        frame.size.width = superview?.frame.size.width ?? frame.size.width
        frame.size.height = totalHeight
        self.frame = frame
        reloadData()
    }
    
    // TODO - add functions for removal of views!
    
    public func viewWithIdentifier(identifier:String) -> UIView? {
        for viewInfo in stackedSubviews {
            if let ident = viewInfo.identifier, identifier == ident {
                return viewInfo.view
            }
        }
        return nil
    }
    
    public func setView(_ identifier:String, hidden:Bool) {
        for viewInfo in stackedSubviews {
            if let ident = viewInfo.identifier, identifier == ident {
                viewInfo.hidden = hidden
                update()
                return
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleSubviews.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewInfo = visibleSubviews[indexPath.row]
        if let cell = viewInfo.view as? UITableViewCell {
            cell.frame.size.width = self.frame.size.width
            return cell
        }
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return visibleSubviews[indexPath.row].height
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return visibleSubviews[indexPath.row].height
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let viewInfo = visibleSubviews[indexPath.row]
        if let callback = viewInfo.callback {
            callback()
        }
    }
 }
