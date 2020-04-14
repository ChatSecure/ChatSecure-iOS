//
//  OTRInviteViewController_Previews.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 4/13/20.
//  Copyright © 2020 Chris Ballinger. All rights reserved.
//

#if DEBUG
import SwiftUI

/// Unfortunately Xcode cannot seem to create Previews with our current build configuration
@available(iOS 13.0, *)
struct OTRInviteViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                OTRInviteViewController(account: OTRAccount(username: "user@example.com", accountType: .jabber)!)
            }
            .previewDevice("iPhone 11 Pro Max")
            .previewLayout(.sizeThatFits)
        }
    }
}

#endif
