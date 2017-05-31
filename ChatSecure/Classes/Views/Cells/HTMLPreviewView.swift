//
//  HTMLPreviewView.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 5/30/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRAssets

public class HTMLPreviewView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var domainLabel: UILabel!
    
    public static var nibName: String? {
        return NSStringFromClass(self).components(separatedBy: ".").last
    }
    
    public static var previewView: HTMLPreviewView? {
        guard let nibName = self.nibName else {
            return nil
        }
        return OTRAssets.resourcesBundle.loadNibNamed(nibName, owner: nil, options: nil)?.first as? HTMLPreviewView
    }
    
    public func setURL(_ url: URL?, title: String?) {
        domainLabel.text = url?.host
        titleLabel.text = title ?? OPEN_IN_SAFARI()
    }

}
