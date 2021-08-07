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
/// seems related to using `MACH_O_TYPE=staticlib` for our frameworks
/// https://twitter.com/_andersha/status/1405925636565262341
@available(iOS 13.0, *)
struct OTRInviteViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                OTRInviteViewController(account: OTRXMPPAccount(username: "user@example.com", accountType: .jabber)!)
            }
            .previewDevice("iPhone 12 Pro Max")
            .previewLayout(.sizeThatFits)
        }
    }
}

#endif
