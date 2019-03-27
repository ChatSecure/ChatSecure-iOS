//
//  UIView+OTRAssets.swift
//  OTRAssets
//
//  Created by Chris Ballinger on 6/13/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit


extension UIView {
    
    /// Helper for loading nibs from the OTRAssets bundle
    @objc public static func otr_viewFromNib() -> Self? {
        guard let nibName = self.otr_nibName else {
            return nil
        }
        return otr_viewFromNib(nibName: nibName)
    }
    
    private static func otr_viewFromNib<T>(nibName: String) -> T? {
        guard let nibName = self.otr_nibName else {
            return nil
        }
        return OTRAssets.resourcesBundle.loadNibNamed(nibName, owner: nil, options: nil)?.first as? T
    }
    
    private static var otr_nibName: String? {
        return NSStringFromClass(self).components(separatedBy: ".").last
    }
}
