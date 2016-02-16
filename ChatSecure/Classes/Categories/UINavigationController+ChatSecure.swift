//
//  File.swift
//  ChatSecure
//
//  Created by David Chiles on 12/14/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import UIKit


public extension UINavigationController {
    
    public func otr_baseViewContorllers() -> [UIViewController] {
        var result:[UIViewController] = []
        let viewController = self.viewControllers
        for vc in viewController {
            if let nav = vc as? UINavigationController {
                result.appendContentsOf(nav.otr_baseViewContorllers())
            } else {
                result.append(vc)
            }
        }
        return result
    }
    
}