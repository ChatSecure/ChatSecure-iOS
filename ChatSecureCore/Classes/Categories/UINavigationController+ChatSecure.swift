//
//  File.swift
//  ChatSecure
//
//  Created by David Chiles on 12/14/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import UIKit


extension UINavigationController {
    
    @objc public func otr_baseViewContorllers() -> [UIViewController] {
        var result:[UIViewController] = []
        let viewController = self.viewControllers
        for vc in viewController {
            if let nav = vc as? UINavigationController {
                result.append(contentsOf: nav.otr_baseViewContorllers())
            } else {
                result.append(vc)
            }
        }
        return result
    }
    
}
