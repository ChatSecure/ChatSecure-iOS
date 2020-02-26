//
// Created by Vyacheslav Karpukhin on 20.02.20.
// Copyright (c) 2020 Chris Ballinger. All rights reserved.
//

import Foundation

open class OTRStorageUsageSetting : OTRViewSetting {
    public override init!(title newTitle: String!, description newDescription: String!) {
        super.init(title: newTitle, description: newDescription, viewControllerClass: OTRStorageUsageViewController.self)
    }
}
